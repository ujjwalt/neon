module Neon
  shared_examples "Session" do
    describe "instance method" do
      let(:api) { example.metadata[:api] }
      let(:session) { Session.current }
      let (:another_session) do
        another_session = case api
        when :embedded
          Session::Embedded.new Helpers::Embedded.test_path
        when :rest
          Session::Rest.new "http://localhost:4747"
        end
        another_session.start
        at_exit { another_session.stop }
        another_session
      end

      describe "start" do
        it "should be true if successful" do
          expect(session.start).to be_true
        end
      end

      describe "class" do
        it "should be #{described_class}" do
          expect(Session.class).to eq(described_class)
        end
      end

      # describe "running?" do
      #   context "has different values in embedded mode" do
      #     if api == :embedded
      #       context "before the server has started" do
      #         it "should be false" do
      #           expect(another_session.running?).to be_false
      #         end
      #       end

      #       context "after the server has started" do
      #         it "should be true" do
      #           another_session.start
      #           expect(another_session.running?).to be_true
      #         end
      #       end

      #       context "after the server has stopped" do
      #         it "should be false" do
      #           another_session.stop
      #           expect(another_session.running?).to be_false
      #         end
      #       end
      #     end
      #   end
      # end

      describe "location" do
        it "returns the location of the database" do
          if api == :rest
            expect(session.location).to eq("http://localhost:7474")
            expect(another_session.location).to eq("http://localhost:4747")
          else
            expect(session.location).to eq(:memory)
          end
        end
      end

      describe "set_current" do
        it "should return false when a current session is running" do
          result = Session.set_current another_session
          expect(result).to eq(false)
        end

        it "should return true when there is no current session" do
          another_session # Just call this to initialize this session while the current session is running
          Session.stop
          result = Session.set_current another_session
          expect(result).to eq(true)
        end
      end

      describe "stop" do
        it "should be true if successful" do
          expect(session.stop).to be_true
        end
      end
    end
  end
end