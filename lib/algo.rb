require 'stopwords'
require 'treat'

include Treat::Core::DSL

class Algo
  attr_reader :qualities

  def initialize(options={})
    @qualities=get_qualities options
  end

  def preprocess(options={})
    # debuggersz
    # options[:file]                 = get_file_array options[:file]    || 'Testimonials/11.txt'
    options[:words_to_remove_file] = get_file_array options[:words_to_remove_file] || "#{Rails.root}/lib/Word Lists/stopwords.txt"

    #Arrays passed as filter words are prioritized over files containing filter words
    my_filter = Stopwords::Filter.new options[:words_to_remove_array] || options[:words_to_remove_file]

    #Text passed as input to be filtered is prioritized over files
    options[:text] =  options[:text].split unless options[:text].nil?   #Split the text if it exists
    (my_filter.filter options[:text] || options[:file])*" " #*" " Turns the array into a string
  end

  def get_file_array(file_name)
    (File.read file_name).split
  end

  def apply_all(paragraph)
    paragraph.apply(:chunk, :segment, :tokenize, :category)
  end

  def get_proper_nouns(paragraph)
    proper_nouns=get_from_criteria(paragraph, {first: "NNP", others: "NNP", required_pair: false})

    proper_nouns.reject{|x| (get_file_array "#{Rails.root}/lib/Word Lists/proper_noun_blacklist.txt")
      .map(&:downcase).include? x.downcase}
  end

  def get_from_criteria(paragraph, options={})
    options[:first]    ||= "JJ"   #First word must be an adjective
    options[:others]   ||= "NN"   #Words preceeding the adjective must be nouns
    options[:username] ||= false  #The functionalities will differ when usernames need to be found

    #Require that first and others to be present
    #In this parameter, true is the default for nil values
    options[:required_pair]=( (options[:required_pair].nil?) ? true :
      options[:required_pair]==false ? false :
        (raise ArgumentError.new("The only values allowed are true and false"))  )

    print "Options is ", options, "\n"

    criterias=[]

    #paragraph.children = sentences, phrases, etc.
    paragraph.children.each  do |s|
      c=s.children

      #Used to skip iterations so that matches don't overlap
      #["John Doe", "Doe"] does not occur
      skip_next=0

      #s.children = words, punctuations, etc.
      s.children.length.times do |i|
        if skip_next > 0
          skip_next -= 1
          next
        end

        #Check if the current word matches the first tag
        if c[i].tag ==  options[:first]
          criteria=[]
          criteria.push c[i].to_s
          j=1;

          #Add the preceeding words if they match the others tag
          #while making sure not to go pass the array length
          while (i+j)<c.length && c[i+j].tag.start_with?(options[:others])
            criteria.push c[i+j].to_s
            j+=1
          end

  #        puts "Criteria length is ", criteria.length
  #        puts "Criteria is ", criteria, " Options is ",options

          #Only add to the criterias list if
          #both criterias (:first, :others) are needed
          if options[:required_pair]
            criterias.push(criteria*" ") if criteria.length > 1

          #Add even if only the first criteria (:first) matches
          else
            criterias.push(criteria*" ") if criteria.length > 0
          end

          #Skip the next words
          #There is a -1 since we are currently at our first word
          skip_next= (criteria.length-1)
        end
      end
    end
    criterias
  end

  def get_qualities(options={})
    #Preprocess the paragraph
    p=paragraph preprocess options
    p apply_all p
    p.print_tree

    #Initialize the qualities hash map
    qualities={}

    #Get the verbs excluding the 's
    qualities[:verbs]         = p.verbs.reject{|x| x.class==Treat::Entities::Enclitic}.map(&:to_s)

    #Get the proper nouns
    qualities[:proper_nouns]  = get_proper_nouns p

    #Get the descriptions e.g. "good service", "timely manner", "creative problem resolution"
    qualities[:descriptions]  = get_from_criteria p

    #Removes the duplicates
    qualities.each_key{|k| qualities[k]=qualities[k].uniq}

    return qualities
  end

  #Print the qualities with some formatting
  def print_qualities
    puts
    @qualities.each { |k, v| print "Key: #{k}",(k.length<10 ? "\t\t":"\t"),  "Value: #{v} \n" }
    puts
  end
end

# my_quality=Algo.new({file: 'Testimonials/3.txt'})
# my_quality.print_qualities
