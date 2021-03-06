# frozen_string_literal: true

require 'spec_helper'

describe HTMLProofer do
  describe '#failed_tests' do
    it 'is a list of the formatted errors' do
      broken_link_internal_filepath = "#{FIXTURES_DIR}/links/broken_link_internal.html"
      proofer = run_proofer(broken_link_internal_filepath, :file)
      expect(proofer.failed_tests).to eq(['spec/html-proofer/fixtures/links/broken_link_internal.html: internally linking to ./notreal.html, which does not exist (line 5)', 'spec/html-proofer/fixtures/links/broken_link_internal.html: internally linking to ./missingImageAlt.html, which does not exist (line 6)'])
    end
  end

  describe '#failures' do
    it 'is an array of Issue' do
      broken_link_internal_filepath = "#{FIXTURES_DIR}/links/broken_link_internal.html"
      proofer = run_proofer(broken_link_internal_filepath, :file)
      expect(proofer.failures.length).to eq(2)
      expect(proofer.failures[0].class).to eq(HTMLProofer::Issue)
      expect(proofer.failures[0].path).to eq('spec/html-proofer/fixtures/links/broken_link_internal.html')
      expect(proofer.failures[0].desc).to eq('internally linking to ./notreal.html, which does not exist')
    end
  end

  describe '#files' do
    it 'works for directory that ends with .html' do
      folder = "#{FIXTURES_DIR}/links/_site/folder.html"
      proofer = HTMLProofer.check_directory(folder)
      expect(proofer.files).to eq(["#{folder}/index.html"])
    end
  end

  describe '#options' do
    it 'strips out undesired Typhoeus options' do
      folder = "#{FIXTURES_DIR}/links/_site/folder.html"
      proofer = HTMLProofer.check_file(folder, verbose: true)
      expect(proofer.options[:verbose]).to eq(true)
      expect(proofer.options[:typhoeus][:verbose]).to eq(nil)
    end

    it 'takes options for Parallel' do
      folder = "#{FIXTURES_DIR}/links/_site/folder.html"
      proofer = HTMLProofer.check_file(folder, parallel: { in_processes: 3 })
      expect(proofer.options[:parallel][:in_processes]).to eq(3)
      expect(proofer.options[:typhoeus][:in_processes]).to eq(nil)
    end

    describe 'sorting' do
      it 'understands sorting by path' do
        output = send_proofer_output("#{FIXTURES_DIR}/sorting/path", :directory, log_level: :info)

        expect(output.strip).to eq('
- spec/html-proofer/fixtures/sorting/path/multiple_issues.html
  *  image gpl.png does not have an alt attribute (line 7)
  *  internal image gpl.png does not exist (line 7)
  *  tel: contains no phone number (line 5)
     <a href="tel:">Tel me</a>
- spec/html-proofer/fixtures/sorting/path/single_issue.html
  *  image has a terrible filename (./Screen Shot 2012-08-09 at 7.51.18 AM.png) (line 1)

HTML-Proofer found 4 failures!
        '.strip)
      end

      it 'understands sorting by issue' do
        output = send_proofer_output("#{FIXTURES_DIR}/sorting/issue", :directory, log_level: :info, error_sort: :desc)
        expect(output.strip).to eq('
- image ./gpl.png does not have an alt attribute
  *  spec/html-proofer/fixtures/sorting/issue/broken_image_one.html (line 1)
  *  spec/html-proofer/fixtures/sorting/issue/broken_image_two.html (line 1)
- internal image ./gpl.png does not exist
  *  spec/html-proofer/fixtures/sorting/issue/broken_image_one.html (line 1)
  *  spec/html-proofer/fixtures/sorting/issue/broken_image_two.html (line 1)
- internal image NOT_AN_IMAGE does not exist
  *  spec/html-proofer/fixtures/sorting/issue/broken_image_two.html (line 4)

HTML-Proofer found 5 failures!
        '.strip)
      end

      it 'understands sorting by status' do
        output = send_proofer_output("#{FIXTURES_DIR}/sorting/status", :directory, typhoeus: { followlocation: false }, log_level: :info, error_sort: :status)
        expect(output.gsub(/\s*$/, '')).to eq('
- -1
  *  spec/html-proofer/fixtures/sorting/status/broken_link.html: internally linking to nowhere.fooof, which does not exist (line 3)
- 301
  *  spec/html-proofer/fixtures/sorting/status/a_404.html: External link http://upload.wikimedia.org/wikipedia/en/thumb/not_here.png failed: 301
  *  spec/html-proofer/fixtures/sorting/status/broken_link.html: External link http://upload.wikimedia.org/wikipedia/en/thumb/fooooof.png failed: 301
HTML-Proofer found 3 failures!
  '.strip)
      end
    end

    describe 'file ignores' do
      it 'knows how to ignore a file by string' do
        options = { file_ignore: ["#{FIXTURES_DIR}/links/broken_hash_internal.html"] }
        broken_hash_internal_filepath = "#{FIXTURES_DIR}/links/broken_hash_internal.html"
        proofer = run_proofer(broken_hash_internal_filepath, :file, options)
        expect(proofer.failed_tests).to eq([])
      end

      it 'knows how to ignore a file by regexp' do
        options = { file_ignore: [/broken_hash/] }
        broken_hash_internal_filepath = "#{FIXTURES_DIR}/links/broken_hash_internal.html"
        proofer = run_proofer(broken_hash_internal_filepath, :file, options)
        expect(proofer.failed_tests).to eq([])
      end

      it 'knows how to ignore multiple files by regexp' do
        options = { file_ignore: [%r{.*/javadoc/.*}, %r{.*/catalog/.*}] }
        broken_folders = "#{FIXTURES_DIR}/links/folder/multiples"
        proofer = run_proofer([broken_folders], :directories, options)
        expect(proofer.failed_tests).to eq([])
      end

      it 'knows how to ignore a directory by regexp' do
        options = { file_ignore: [/\S\.html/] }
        links_dir = "#{FIXTURES_DIR}/links"
        proofer = run_proofer([links_dir], :directories, options)
        expect(proofer.failed_tests).to eq([])
      end
    end
  end

  describe 'ignored checks' do
    it 'knows how to ignore checks' do
      options = { checks_to_ignore: ['ImageRunner'] }
      proofer = make_proofer("#{FIXTURES_DIR}/links/broken_link_external.html", :file, options)
      expect(proofer.checks).to_not include 'ImageRunner'
    end

    it 'does not care about phoney ignored checks' do
      options = { checks_to_ignore: ['This is nothing.'] }
      proofer = make_proofer("#{FIXTURES_DIR}/links/broken_link_external.html", :file, options)
      expect(proofer.checks.length).to eq(3)
    end
  end

  describe 'external only' do
    it 'knows how to ignore non-external link failures' do
      options = { external_only: true }
      missing_alt_filepath = "#{FIXTURES_DIR}/images/missing_image_alt.html"
      proofer = run_proofer(missing_alt_filepath, :file, options)
      expect(proofer.failed_tests).to eq([])
    end

    it 'still reports external link failures' do
      options = { external_only: true }
      external = "#{FIXTURES_DIR}/links/broken_link_external.html"
      proofer = run_proofer(external, :file, options)
      expect(proofer.failed_tests.length).to eq(1)
    end

    it 'ignores status codes when asked' do
      proofer = run_proofer(['www.github.com/github/notreallyhere'], :links, http_status_ignore: [404])
      expect(proofer.failed_tests.length).to eq(0)
    end
  end

  describe 'multiple directories' do
    it 'works' do
      dirs = ["#{FIXTURES_DIR}/sorting/path", "#{FIXTURES_DIR}/sorting/issue"]
      output = send_proofer_output(dirs, :directories)

      expect(output).to match('sorting/path')
      expect(output).to match('sorting/issue')
      expect(output).to_not match('sorting/status')
    end
  end
end
