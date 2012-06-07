require 'pry-remote'

module PryRemote
  class Server
    # Override the call to Pry.start to save off current Server, pass a
    # pry_remote flag so pry-debugger knows this is a remote session, and not
    # kill the server right away.
    def run
      if PryDebugger.current_remote_server
        raise 'Already running a pry-remote session!'
      else
        PryDebugger.current_remote_server = self
      end

      setup
      Pry.start @object, {
        :input  => client.input_proxy,
        :output => client.output,
        :pry_remote => true
      }
    end

    # Override to reset our saved global current server session.
    alias_method :teardown_existing, :teardown
    def teardown
      return if @torn

      teardown_existing
      PryDebugger.current_remote_server = nil
      @torn = true
    end
  end
end

# Ensure cleanup when a program finishes without another break. For example,
# 'next' on the last line of a program won't hit PryDebugger::Processor#run,
# which normally handles cleanup.
at_exit do
  if PryDebugger.current_remote_server
    PryDebugger.current_remote_server.teardown
  end
end
