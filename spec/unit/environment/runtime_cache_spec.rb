require "librarian/environment/runtime_cache"

module Librarian
  class Environment
    describe RuntimeCache do

      let(:rtc) { described_class.new }
      let(:key) { ["brah", "nick"] }
      let(:key_x) { ["brah", "phar"] }
      let(:key_y) { ["rost", "phar"] }

      def triple(keypair)
        [rtc.include?(*keypair), rtc.get(*keypair), rtc.memo(*keypair){yield}]
      end

      context "originally" do
        specify { expect(triple(key){9}).to eql([false, nil, 9]) }
      end

      context "after put" do
        before { rtc.put(*key){6} }

        specify { expect(triple(key){9}).to eql([true, 6, 6]) }
        specify { expect(triple(key_x){9}).to eql([false, nil, 9]) }
        specify { expect(triple(key_y){9}).to eql([false, nil, 9]) }
      end

      context "after put then delete" do
        before { rtc.put(*key){6} }
        before { rtc.delete *key }

        specify { expect(triple(key){9}).to eql([false, nil, 9]) }
        specify { expect(triple(key_x){9}).to eql([false, nil, 9]) }
        specify { expect(triple(key_y){9}).to eql([false, nil, 9]) }
      end

      context "after memo" do
        before { rtc.memo(*key){6} }

        specify { expect(triple(key){9}).to eql([true, 6, 6]) }
        specify { expect(triple(key_x){9}).to eql([false, nil, 9]) }
        specify { expect(triple(key_y){9}).to eql([false, nil, 9]) }
      end

      context "after memo then delete" do
        before { rtc.memo(*key){6} }
        before { rtc.delete *key }

        specify { expect(triple(key){9}).to eql([false, nil, 9]) }
        specify { expect(triple(key_x){9}).to eql([false, nil, 9]) }
        specify { expect(triple(key_y){9}).to eql([false, nil, 9]) }
      end

    end
  end
end
