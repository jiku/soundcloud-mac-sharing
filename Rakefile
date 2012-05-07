require 'rake/clean'
require 'fileutils'
require 'mustache'
require 'redcarpet'


source = "SCDesktopSharingKit/SCDesktopSharingKit/"
destination = 'docs/'
files = ['AppConstants.h']


# HELPERS ====================================================================

def render_markdown(source, destination)
  puts "rake_md: #{source} -> #{destination}"

  html = Redcarpet.new(File.read(source)).to_html
  # We're using a Docco like template for the Readme
  html = Mustache.render(File.read('Readme.mustache'), docs: html)

  FileUtils.mkdir_p File.dirname(destination)
  File.open(destination, 'wb') { |fd| fd.write(html) }
end


# DOCS WITH ROCCO HELPER =====================================================

# Require rocco, else 
begin
  require 'rocco/tasks'
  Rocco::make destination, "#{source}**/*.h"
rescue LoadError
  abort "#$! -- is the rocco gem installed?"
end

# Build the list of files to generate
docs_to_build = []
files.each do |source_file|
  dest_file = source_file.sub(Regexp.new("#{File.extname(source_file)}$"), ".html")
  dest_file = "#{destination}#{source}#{dest_file}"
  docs_to_build << dest_file
end


# DOCS TASK ==================================================================

desc 'Build docs using rocco'
task :docs => docs_to_build do
  render_markdown('Readme.md', 'docs/index.html')
end
CLEAN.include "docs/index.html" if defined? CLEAN


# GITHUB PAGES TASK ==========================================================

# Note: (Ullrich) 02/04/2012: This is stolen from the rocco Rakefile itself
desc 'Update gh-pages branch'
task :pages => [:gp_pages_branch, 'docs/.git', :docs] do
  rev = `git rev-parse --short HEAD`.strip
  Dir.chdir 'docs' do
    sh "git add *.html"
    sh "git commit -m 'rebuild pages from #{rev}'" do |ok,res|
      if ok
        verbose { puts "gh-pages updated" }
        sh "git push -q o HEAD:gh-pages"
      end
    end
  end
end

file '.git/refs/heads/gh-pages' do 
  abort 'Please create (or pull) the gp-pages branch.'
end
task :gp_pages_branch => '.git/refs/heads/gh-pages'

# Update the pages/ directory clone
file 'docs/.git' => ['docs/', '.git/refs/heads/gh-pages'] do |f|
  sh "cd docs && git init -q && git remote add o ../.git" if !File.exist?(f.name)
  sh "cd docs && git fetch -q o && git reset -q --hard o/gh-pages && touch ."
end
CLOBBER.include 'docs/.git'

