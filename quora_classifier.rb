require_relative 'classifier.rb'

class QuoraClassifier

  @file
  @debug
  @trainData
  @queryData
  @queryDataId
  @result
  
  @classifier
  
  def initialize(file = "", debug = false)
    if file == ""
      @file = false
    else
      @file = File.new file, "r"
    end   
    @debug = debug
    @trainData = Array.new
    @queryDataId = Array.new
    @queryData = Array.new
  end
  
  def getLine()
    if @file
      return @file.gets
    else
      return gets
    end
  end
  
  def solve_problem()
    if @debug
      t1 = Time.new
    end
    read_data
    classifier = Classifier.new @debug
    classifier.set_train_data @trainData, 1000
    classifier.train 170, 50
    results = classifier.classify @queryData
    
    right = 0
    wrong = 0
    
    0.upto results.row_size-1 do |i|
      if results[i, 0] >= 0.50
        result = "+1"
      else
        result = "-1"
      end
      
      if @debug
        if @result[i][1] == result
          right += 1
        else
          wrong += 1
        end
      end
      
      if @debug
        puts "#{@queryDataId[i]}:#{@result[i][0]} #{result}:#{@result[i][1]} #{results[i, 0]}"
      else
        puts "#{@queryDataId[i]} #{result}"
      end
    end
    
    if @debug
      total = right+wrong
      errorPercentage = (wrong.to_f / total) * 100
      puts "Total #{total} Right: #{right} Wrong: #{wrong} Error(%): #{errorPercentage}"
      t2 = Time.new
      puts "solve_problem: #{t2-t1}"
    end
  end
  def read_data() # read problem data
    read_train_data
    read_query_data
    if @debug
      read_result_data
    end
  end # read_data end
  
  def read_result_data
    @result = Array.new
    file = File.new "output00.txt", "r"
    1.upto @queryDataId.length do
      line = file.gets
      line = line.split " "
      @result << line
    end
  end
  
  def read_query_data
    if @debug
      t1 = Time.new
    end
    
    line = self.getLine
    
    numberOfQuery = line.to_i
    last = numberOfQuery - 1
    
    1.upto numberOfQuery do |i|
      line = self.getLine
      
      line = line.gsub /([0-9])+:/, "" # removing att number and :
      row = (line.split " ")
      
      @queryDataId << row[0]
      @queryData << row[1..last]

    end
    
    if @debug
      t2 = Time.new
      puts "read_query_data: #{t2-t1}"
    end
  end
    
  def read_train_data
    if @debug
      t1 = Time.new
    end
    
    line = self.getLine
  
    line = line.split " "
  
    numberOfTrainData = line[0].to_i
    numberOfAttribute = line[1].to_i
    
    @trainData = Array.new
    
    1.upto numberOfTrainData do |i|
      
      line = self.getLine
      
      line = line.gsub /([0-9])+:/, "" # removing att number and :
      @trainData << (line.split " ")
      if(@trainData[i-1][1] == "+1")
        @trainData[i-1][1] = 1
      else
        @trainData[i-1][1] = 0
      end
    end
 
    if @debug
      t2 = Time.new
      puts "read_train_data: #{t2-t1}"
    end
  end # read_train_data end
end # class QuoraClassifier end

qr = QuoraClassifier.new("input00.txt", true)
qr.solve_problem