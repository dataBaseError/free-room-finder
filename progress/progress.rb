###############################################################################
# Copyright (c) 2014 Jeremy S. Bradbury, Joseph Heron
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###############################################################################

class Progress
    attr_accessor :orig_std, :total_length, :count

    BAR_LENGTH = 78
    OFFSET = 2

    def initialize(title=nil, second=false)
        @orig_std = $stdout.clone
        @total_length = 0
        @count = 0
        @app_title = title
        @second = second
    end

    def percentComplete(list=nil)
        print_bar(list)

        @count += 1
    end

    def puts(value)

        if value.class.name == Array.to_s
            
            value.each do |val|
                @orig_std.puts val
            end

        else
            @orig_std.puts value
        end
       
    end

    def print_bar(list=nil)
        cur_percent = (@count.to_f/@total_length)*100

        if !@second
            # Print clear character since system "clear" does not work from bash script
            @orig_std.print "\033c"
        end

        if @app_title
            @orig_std.puts @app_title
        end

        if list
            list.each do |item|
                @orig_std.puts item
            end
        end

        @orig_std.puts "Percent Complete #{format("%.1f",cur_percent)}%"

        @orig_std.print "["

        (BAR_LENGTH-OFFSET).times do |v|
            if v <= ((BAR_LENGTH-OFFSET) * (cur_percent/100)).ceil
                @orig_std.print "#"
            else
                @orig_std.print " "
            end
        end

        @orig_std.print "]"

        # Force the next print line to be on a new line
        @orig_std.print "\n"
    end

ensure

    # Close the output stream
    if @orig_std
        @orig_std.close
    end
end

=begin
pi = Progress.new

$stdout.reopen("temp", "a")

pi.total_length = 100

pi.puts("HERE")
pi.percentComplete("NAME")
puts "HERE"
=end