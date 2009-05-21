#!/usr/bin/ruby -w

require 'rubygems'
require 'rake/gempackagetask'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/testtask'

#Configuration variables.
PRODUCT_NAME = "Zyps"
PRODUCT_VERSION = "0.7.7"
SUMMARY = "A game library for Ruby"
AUTHOR = "Jay McGavren"
AUTHOR_EMAIL = "jay@mcgavren.com"
WEB_SITE = "http://jay.mcgavren.com/#{PRODUCT_NAME.downcase}/"
EXECUTABLES = [
	PRODUCT_NAME.downcase
]


#Set up rdoc.
RDOC_OPTIONS = [
	"--title", "#{PRODUCT_NAME} - #{SUMMARY}",
	"--main", "README.txt"
]


desc "Create a gem by default"
task :default => [:test, :gem]


desc "Create documentation"
Rake::RDocTask.new do |task|
	task.rdoc_dir = "doc"
	task.rdoc_files = FileList[
		"lib/**/*.rb",
		"*.txt",
	].exclude(/\bsvn\b/).to_a
	task.options = RDOC_OPTIONS
end


desc "Test the package"
Rake::TestTask.new do |test|
	test.libs << "lib"
	test.test_files = FileList["test/**/test_*.rb"]
end


begin
	require 'spec/rake/spectask'
	Spec::Rake::SpecTask.new do |task|
		task.spec_files = FileList['spec/**/*_spec.rb']
	end
	desc "Generate spec doc HTML files"
	Spec::Rake::SpecTask.new do |task|
		task.name = :spec_docs
		task.spec_files = FileList['spec/**/*_spec.rb']
		task.spec_opts << "--format html:spec_doc.html"
		task.fail_on_error = false
	end
	desc "Run user stories"
	task :stories do
		FileList["stories/*.rb"].each {|f| ruby f}
	end
	task :default => :spec
rescue LoadError => exception
	warn "Could not load rSpec - it might not be installed."
end


begin
	require 'ruby-prof'
	desc "Run profiler"
	task :profile do
		FileList["profile/*.rb"].each do |f|
			output = `ruby-prof --printer=graph_html #{f} > #{f.sub(/\.rb/, '.htm')}`
			fail "Error #{$?}: #{output}" unless $? == 0
		end
	end
rescue LoadError => exception
	warn "Could not load ruby-prof - it might not be installed."
end


begin
	require 'flay'
	desc "Run duplicate code analyzer"
	task :flay do
		output = `flay #{FileList["lib/**/*.rb"].join(' ')}`
		fail "Error #{$?}: #{output}" unless $? == 0
		puts output
	end
rescue LoadError => exception
	warn "Could not load flay - it might not be installed."
end


desc "Run a demonstration"
task :demo do
	ruby "-I lib bin/zyps_demo"
end

desc "Run the GUI"
task :gui do
	ruby "-I lib bin/zyps zyps.cfg"
end


desc "Package a gem"
specification = Gem::Specification.new do |spec|
	spec.name = PRODUCT_NAME.downcase
	spec.version = PRODUCT_VERSION
	spec.author = AUTHOR
	spec.email = AUTHOR_EMAIL
	spec.homepage = WEB_SITE
	spec.platform = Gem::Platform::RUBY
	spec.summary = SUMMARY
	spec.add_dependency("wxruby", ">= 1.9.2")
	spec.rubyforge_project = PRODUCT_NAME.downcase
	spec.require_path = "lib"
	spec.autorequire = PRODUCT_NAME.downcase
	spec.test_files = Dir.glob("test/**/test_*.rb")
	spec.has_rdoc = true
	spec.rdoc_options = RDOC_OPTIONS
	spec.extra_rdoc_files = ["README.txt", "COPYING.LESSER.txt", "COPYING.txt"]
	spec.files = FileList[
		"*.txt",
		"bin/**/*",
		"lib/**/*",
		"test/**/*",
		"doc/**/*"
	].exclude(/\bsvn\b/).to_a
	spec.executables = EXECUTABLES
end
Rake::GemPackageTask.new(specification) do |package|
	package.need_tar = true
end


CLOBBER.include(%W{doc})
