# frozen_string_literal: true

describe SitePrism::ElementChecker do
  let!(:section_locator) { instance_double('Capybara::Node::Element') }

  shared_examples 'a page' do
    describe '#all_there?' do
      context 'with the default recursion setting' do
        subject { page.all_there? }

        it { is_expected.to be true }

        it 'checks only the `expected_elements`' do
          expected_items.each do |name|
            expect(page).to receive(:there?).with(name).once.and_call_original
          end

          subject
        end

        it "does not check items that aren't defined as `expected_elements`" do
          expect(page).not_to receive(:there?).with(:element_two)

          subject
        end
      end

      context 'with recursion set to none' do
        subject { page.all_there?(recursion: :none) }

        it { is_expected.to be true }

        it 'checks only the `expected_elements`' do
          expected_items.each do |name|
            expect(page).to receive(:there?).with(name).once.and_call_original
          end

          subject
        end

        it "does not check items that aren't defined as `expected_elements`" do
          expect(page).not_to receive(:there?).with(:element_two)

          subject
        end
      end

      context 'with recursion set to one' do
        subject { page.all_there?(recursion: :one) }

        let(:recursion_instance) { SitePrism::RecursionChecker.new(page) }

        before do
          allow(page).to receive(:section_one).and_return(section)
          allow(SitePrism::RecursionChecker).to receive(:new).and_return(recursion_instance)
        end

        it { is_expected.to be true }

        it 'checks each item in `expected_elements`' do
          expected_items.each do |name|
            expect(recursion_instance).to receive(:there?).with(name).once.and_call_original
          end

          subject
        end

        it 'checks all first-generation descendants' do
          expect(section).to receive(:all_there?).and_call_original
          expect(section).to receive(:there?).with(:inner_element_one).and_return(true)
          expect(section).to receive(:there?).with(:inner_element_two).and_return(true)
          expect(section).to receive(:there?).with(:iframe).and_return(true)

          subject
        end

        it "doesn't check any items that aren't marked as `expected_items`" do
          expect(page).not_to receive(:there?).with(:element_two)

          subject
        end
      end

      context 'with recursion set to an invalid value' do
        # This stops the stdout process leaking between tests
        subject { page.all_there?(recursion: 'go nuts') }

        before { wipe_logger! }

        it 'does not check any elements' do
          expect(page).not_to receive(:there?)

          subject
        end

        it 'sends an error to the SitePrism logger' do
          log_messages = capture_stdout do
            SitePrism.configure { |config| config.log_level = :ERROR }
            subject
          end

          expect(lines(log_messages)).to eq(1)
        end
      end
    end

    describe '#elements_present' do
      it 'lists the SitePrism objects that are present on the page' do
        expect(page.elements_present)
          .to eq(%i[element_one element_three elements_one section_one sections_one])
      end
    end
  end

  context 'with a Page defined using CSS locators' do
    let(:page) { CSSPage.new }
    let(:section) { CSSSection.new(page, section_locator) }
    let(:expected_items) { CSSPage.expected_items }

    it_behaves_like 'a page'
  end

  context 'with a Page defined using XPath locators' do
    let(:page) { XPathPage.new }
    let(:section) { XPathSection.new(page, section_locator) }
    let(:expected_items) { XPathPage.expected_items }

    it_behaves_like 'a page'
  end
end
