require 'language_classifier'
require 'madeleine_commands'

class ClassifierController

  SEED_CATEGORIES = %w[afrikaans danish english filipino french hungarian latin romanian]

  def self.process(*args, output)
    options = process_options(*args, output)

    if self.respond_to?(options[:command])
      result = self.send(options[:command], options)
      options[:output].puts result if result
      result
    else
      options[:output].puts "Command not found", "",
                            "Training: bin/classify train -f FILE_PATH -c CATEGORY",
                            "Classification: bin/classify classify -f FILE_PATH",
                            "Seed: bin/classify seed",
                            "Clear All Data: bin/classify clear"
    end
  end

  private

  def self.madeleine(location)
    SnapshotMadeleine.new(location) do
      LanguageClassifier::Classifier.new
    end
  end

  def self.process_options(*args, output)
    options = Hash.new
    options[:command] = args.first || :not_found
    options[:output] = output
    args.each do |arg|
      case arg
      when '-f'
        filename = args[args.index(arg) + 1]
        filename && File.exists?(filename) ? options[:document] = File.open(filename, "r").read : options[:output].puts("The file you requested could not be found")
      when '-c'
        category = args[args.index(arg) + 1]
        category ? options[:category] = category : options[:output].puts("No category supplied")
      when '--db'
        options[:madeleine] = args[args.index(arg) + 1]
      end
    end
    options[:madeleine] ||= 'tmp/language_classifier'
    options
  end

  def self.train(options)
    if options[:document] && options[:category]
      madeleine(options[:madeleine]).execute_command(MadeleineCommands.train_command(options[:category], options[:document]))
      madeleine(options[:madeleine]).take_snapshot
    end
  end

  def self.classify(options)
    if options[:document]
      madeleine(options[:madeleine]).execute_query(MadeleineCommands.classify_query(options[:document]))
    end
  end

  def self.seed(options)
    SEED_CATEGORIES.each do |category|
      self.train(category: category,
                  document: File.open(File.expand_path('../../', __FILE__) + "/samples/#{category}.txt", "r").read,
                  madeleine: options[:madeleine])
    end
  end

  def self.clear(options)
    directory_name = File.expand_path('../../', __FILE__) + "/#{options[:madeleine]}"
    if Dir.exists?(directory_name)
      Dir.entries(directory_name).each do |filename|
        File.unlink("#{directory_name}/#{filename}") if File.file?("#{directory_name}/#{filename}")
      end
      Dir.unlink(directory_name)
    end
  end

end