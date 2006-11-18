class LineSeparator
  def initialize
    @input = []
  end

  def extract(data)
    data_lines = data.split("\n",-1)
    @input << data_lines.shift

    return [] if data_lines.empty?

    data_lines.unshift( @input.join )
    @input = [data_lines.pop]
    data_lines.collect {|line| yield(line)}
  end
end
