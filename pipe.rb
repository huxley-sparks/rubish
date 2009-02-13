
class Rubish::Pipe
  attr_reader :cmds
  def initialize(&block)
    @cmds = []
    if block
      mu = Rubish::Mu.new &(self.method(:mu_handler).to_proc)
      mu.__instance_eval(&block)
    end
    # dun wanna handle special case for now
    raise "pipe length less than 2" if @cmds.length < 2
  end

  def mu_handler(m,args,block)
    if m == :ruby
      raise "not supported yet"
      @cmds << [args,block]
    else
      @cmds << Rubish::Command.new(m,args,block)
    end
  end

  def exec
    # pipes == [i0,o1,i1,o2,i2...in,o0]
    # i0 == $stdin
    # o0 == $stdout
    pipe = nil # r, w
    @cmds.each_index do |index|
      if index == 0 # head
        i = $stdin
        pipe = IO.pipe
        o = pipe[1] # w
      elsif index == (@cmds.length - 1) # tail
        i = pipe[0]
        o = $stdout
      else # middle
        i = pipe[0] # r
        pipe = IO.pipe
        o = pipe[1]
      end

      cmd = @cmds[index]
      if child = fork # children
        #parent
        i.close unless i == $stdin
        o.close unless o == $stdout
      else
        $stdin.reopen(i)
        $stdout.reopen(o)
        Kernel.exec cmd.cmd
      end
    end
    
    ps = Process.waitall
    #pp ps
  end
end
