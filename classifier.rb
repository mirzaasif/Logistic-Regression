require 'matrix'

class Classifier
  # Data for train
  @trainY
  @trainX
 
  # Data for test
  @testY
  @testX
  
  # Data for validation
  @validateY
  @validateX
  
  @scaleArray
  @thetaArray
  
  # Matrix structure for calculation
  @xMatrix
  @yMatrix
  @thetaMatrix
  
  @debug
  
  def initialize(debug = false)
    init_data
    @debug = debug
  end
  
  def init_data()
    @trainY = Array.new
    @trainX = Array.new
 
    @testY = Array.new
    @testX = Array.new
  
    @validateY = Array.new
    @validateX = Array.new
    
    @scaleArray = Array.new
    
    @theta = Array.new
  end
  
  def sigmoid(z)
    z.collect { |e| (1.0 / (1.0 + Math.exp(-e)))}
  end
  
  def hypothesis(x, theta)
    sigmoid (x * theta)
  end
  
  def set_train_data(data, maxSample = 0, shuffle = false)
    if @debug
      t1 = Time.new
    end
    
    init_data
    
    if(maxSample == 0 or data.length < maxSample)
      sample = data
    else
      if shuffle
        data.shuffle!
      end
      sample = data[0..maxSample-1]
    end
    
    last = data[0].length - 1;
    
    0.upto last-1 do
      @scaleArray << {:avg => 0.0, :min => nil, :max => nil, :total => 0.0, :input => 0, :avgVar => nil}
    end
        
    sample.each do |row|
      @trainY << [row[1].to_f]
      newRow = ([1.0] + row[2..last])
      1.upto last-1 do |i|
        newRow[i] = newRow[i].to_f
        update_scale_data newRow[i], i 
      end
      @trainX << newRow
    end
    
    update_scale_avg # updating avg column values
    
    feature_scale! @trainX # performing feature scaling on data
    
    return
    if @debug
      t2 = Time.new
      puts "set_train_data: #{t2-t1}"
    end
  end # set_train_data end
  
  def feature_scale!(data) # apply feature scale on data
    cols = data[0].length-1
    rows = data.length - 1
    cols.downto 1 do |col| # scaling without x0 which is 1
      range = @scaleArray[col][:max] - @scaleArray[col][:min]
      ratio = 
      deleted = false
      allRowsVar = 0.0 
      0.upto rows do |row|
        if range != 0.0
          allRowsVar += (data[row][col] - @scaleArray[col][:avg]).abs
          data[row][col] = (data[row][col] - @scaleArray[col][:avg]) / range  
        else
          data[row].delete_at col # if range is 0 removing that feature from data
          deleted = true
        end
      end
      #@scaleArray[col][:avg_var] = allRowsVar / data.length
      if @scaleArray[col][:avgVar] == nil
        @scaleArray[col][:avgVar] = allRowsVar / data.length
      end
      
      ratio = @scaleArray[col][:avgVar] / @scaleArray[col][:avg]
      if (!deleted and (ratio <= 0.4))
        deleted = true
        0.upto rows do |row|
          data[row].delete_at col
        end
      end
      
      #puts "#{@scaleArray[col][:avg_var] / @scaleArray[col][:avg]} #{@scaleArray[col][:avg]}  #{@scaleArray[col][:avg]/range} #{@scaleArray[col][:min]} #{@scaleArray[col][:max]} #{@scaleArray[col][:max] - @scaleArray[col][:min]} "
      
      if !deleted and ratio >= 1.5
        #puts @scaleArray[col][:avg_var] / @scaleArray[col][:avg]
        if ratio >= 1.9
          0.upto rows do |row|
            data[row][col] = (data[row][col] * 6)
          end
        else
          0.upto rows do |row|
            data[row][col] = (data[row][col] * 4)
          end
        end
      end
    end
  end # feature_scale end
  
  def update_scale_avg() # calculate scale array avg after all training data is added
    @scaleArray.each_index do |i| 
      @scaleArray[i][:avg] = @scaleArray[i][:total] / @scaleArray[i][:input]
    end
  end
  
  def update_scale_data(value, columnNo) # updating column min max total to apply feature scaling later
    @scaleArray[columnNo][:input] += 1
    @scaleArray[columnNo][:total] += value
    if @scaleArray[columnNo][:max] == nil or @scaleArray[columnNo][:max] < value
      @scaleArray[columnNo][:max] = value
    end
    if @scaleArray[columnNo][:min] == nil or @scaleArray[columnNo][:min] > value
      @scaleArray[columnNo][:min] = value
    end
  end # update_scale_data end 
  
  def calculate_cost(hMatrix, yMatrix, thetaMatrix, lambda = 0) # calculate cost based on theta, hypothesis and actual Y value
    m = yMatrix.row_size - 1
    cost = 0.0
    0.upto m do |i|
      if yMatrix[i, 0] == 1
        cost -= Math.log hMatrix[i, 0]
      else
        if hMatrix[i, 0] != 1
          cost -= Math.log(1.0 - hMatrix[i, 0])
        else
          cost -= Math.log(1.0 - 0.99)
        end
      end
    end
    
    cost = cost / m
    
    if lambda != 0 # performning regularization
      size = thetaMatrix.row_size - 1
      thetaSum = 0.0
      1.upto size do |i|
        thetaSum += (thetaMatrix[i, 0] ** 2)
      end
      cost += (thetaSum / (2 * m)) * lambda
    else
      return cost
    end  
  end # calculate_cost end
  
  def measure_performance xArray, yArray # function to measure performance
    resultArray = classify(xArray)
    right = 0
    wrong = 0
    resultArray.each_index do |i|
      if resultArray[i].ceil == yArray[i][0].to_i
        right += 1
      else
        wrong +=1
      end
    end
    total = right+wrong
    errorPercentage = (wrong.to_f / total) * 100
    puts "Total #{total} Right: #{right} Wrong: #{wrong} Error(%): #{errorPercentage}"
  end
  
  def classify(data)
    array = Array.new
    0.upto data.length-1 do |i|
      row = Array.new
      row << 1.0
      0.upto data[i].length-1 do |j|
        row << data[i][j].to_f
      end 
      array << row
    end
    feature_scale! array
    xMatrix = Matrix.rows(array)
    hMatrix = hypothesis xMatrix, @thetaMatrix
  end
  
  def gradient_descent(xMatrix, yMatrix, thetaMatrix, alpha = 100.0, lambda = 0.0, maxLoop = 50, currentLoop = 1, hMatrix = nil, cost = nil)
    if hMatrix == nil
      hMatrix = hypothesis xMatrix, thetaMatrix
    end
 
    if cost == nil
       cost = calculate_cost hMatrix, yMatrix, thetaMatrix, lambda
    end

    m = yMatrix.row_size.to_f
     
    hyMatrix = (hMatrix - yMatrix).t
    
    newThetaArray = Array.new
    
    0.upto thetaMatrix.row_size - 1 do |row|
      if row == 0
        temp = (hyMatrix * xMatrix.column(row)) * (alpha / m).to_f
        newThetaArray << [(thetaMatrix[row, 0] - temp[0]).to_f]
      else
        temp = hyMatrix * xMatrix.column(row)
        temp = temp[0].to_f / m
        temp = ((temp + ((lambda * thetaMatrix[row, 0]) / m)) * (alpha)).to_f
        newThetaArray << [thetaMatrix[row, 0] - temp]
      end
    end
    
    newThetaMatrix = Matrix.rows(newThetaArray)
    newHMatrix = hypothesis xMatrix, newThetaMatrix
    newCost = calculate_cost newHMatrix, yMatrix, newThetaMatrix, lambda
    
    if(newCost >= cost)
      alpha = ((alpha * 3.0) / 4.0).to_f
    end
    currentLoop += 1
    
    if(currentLoop > maxLoop)
      if(@debug)
        puts "Cost: #{newCost}"
      end
      return newThetaMatrix
    else
      return gradient_descent xMatrix, yMatrix, newThetaMatrix, alpha, lambda, maxLoop, currentLoop, newHMatrix, newCost  
    end
 
  end # gradient_descent end
  
  def train(alpha = 100, maxLoop = 1000, lambda = 0.00)
    
    @thetaArray = Array.new
    1.upto @trainX[0].length do |i|  
      @thetaArray << [0] # initializing theta = 0
    end 
    
    @thetaMatrix = Matrix.rows(@thetaArray, false)
    @xMatrix = Matrix.rows(@trainX, false)
    @yMatrix = Matrix.rows(@trainY, false)
    
    @thetaMatrix = gradient_descent @xMatrix, @yMatrix, @thetaMatrix, alpha, lambda, maxLoop
    
    if @debug
      puts @thetaMatrix
    end
  end # train end
  
end # class Classifier end
