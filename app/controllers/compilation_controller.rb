require 'timeout'

class CompilationController < ApplicationController

  def compile
    # To deal with the increasing number of Java processes...
    # https://bitbucket.org/brunosoliveira/systemfcompiler/issue/97/java-process-not-terminated-with-programs
    puts "Number of Java processes: #{number_of_java_processes}"
    if number_of_java_processes > 3
      puts "killall java!"
      killall_java
    end

    if !params[:source].present?
      head :bad_request
    else
      source_path = "Main.sf"
      output_path = "Main.java"

      File.open(source_path, "w") {|f| f.write(params[:source]) }

      require 'timeout'
      message = nil
      begin
        Timeout::timeout(2) do
          # stderr produced by f2j upon parse error is broken, which makes Ruby hangs.
          # I really wish I gave the user also the result of stderr...
          # See this excellent article:
          # http://blog.bigbinary.com/2012/10/18/backtick-system-exec-in-ruby.html
          message = `f2j #{source_path}` # Backticks don't capture stderr by default.
        end
      rescue Timeout::Error
        render json: { :status => :error, :message => "Timeout. Possibly parse error." }
        return
      end

      if File.exists?(output_path)
        output = `cat Main.java`
        File.delete(output_path)

        render json: { :status => :ok, :message => message, :output => output }
      else
        render json: { :status => :error, :message => message }
      end

    end
  end

  def run
    if !params[:source].present?
      head :bad_request
    elsif suspicious?(params[:source])
      render json: { :status => :error, :result => "Code rejected." }
    else
      source_path = "Main.java"
      class_name  = "Main"

      File.open(source_path, "w") {|f| f.write(params[:source]) }

      result = `javac -cp runtime/src #{source_path} 2>&1`

      if File.exists?(class_name)

        begin
          Timeout::timeout(10) do
            result << `java #{class_name} 2>&1`
          end
        rescue Timeout::Error
          render json: {
            :status => :error,
            :message => "Timeout." }
          return
        end

        File.delete(class_name)
      end

      render json: { :status => :ok, :result => result }
    end
  end

  private

  def number_of_java_processes
    `ps | grep java | wc -l`.to_i
  end

  def killall_java
    system("killall java")
  end

  def suspicious?(source)
    patterns = [
      "Process",
      "Runtime",
      "java.io",
      "java.lang.Unsafe",
      "java.lang.ref",
      "java.lang.reflect",
      "sun.io",
      "sun.misc.Unsafe",
    ]
    patterns.any? { |pat| source.include?(pat) }
  end

end
