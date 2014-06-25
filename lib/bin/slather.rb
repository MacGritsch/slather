require 'clamp'
require 'yaml'
require File.join(File.dirname(__FILE__), '..', 'slather')

class SlatherCommand < Clamp::Command

  self.default_subcommand = "coverage"

  subcommand "coverage", "Computes coverage for the supplised project" do

    option "--project, -p", "PROJECT", "Path to the xcodeproj", :attribute_name => :xcodeproj_path

    option ["--travis", "-t"], :flag, "Indicate that the builds are running on Travis CI"

    option ["--coveralls", "-c"], :flag, "Post coverage results to coveralls"
    option ["--simple-output", "-s"], :flag, "Post coverage results to coveralls"

    option ["--build-directory", "-b"], "BUILD_DIRECTORY", "The directory where gcno files will be written to. Defaults to derived data."
    option ["--ignore", "-i"], "IGNORE", "ignore files conforming to a path", :multivalued => true

    def execute
      puts "Slathering..."
          
      setup_service_name
      setup_ignore_list
      setup_build_directory
      setup_coverage_service

      post

      puts "Slathered"
    end

    def setup_build_directory
      project.build_directory = build_directory if build_directory
    end

    def setup_ignore_list
      project.ignore_list = ignore_list if !ignore_list.empty?
    end

    def setup_service_name
      if travis?
        project.ci_service = :travis_ci
      end
    end

    def post
      project.post
    end

    def project
      @project ||= begin
        xcodeproj_path_to_open = xcodeproj_path || Slather::Project.yml["xcodeproj"]
        project = Slather::Project.open(xcodeproj_path_to_open)
      end
    end

    def setup_coverage_service
      if coveralls?
        project.coverage_service = :coveralls
      elsif simple_output?
        project.coverage_service = :terminal
      end
    end

  end

  subcommand "setup", "Configures an xcodeproj for test coverage generation" do

    parameter "[xcodeproj]", "Path to the xcodeproj", :attribute_name => :xcodeproj_path

    def execute
      project = Slather::Project.open(xcodeproj_path)
      project.setup_for_coverage
      project.save
    end

  end
end