require 'spec_helper'
require "savon/mock/spec_helper"

describe ThreeDeeCart::Order do
  include Savon::SpecHelper

  before(:all) { 
    savon.mock!
    ThreeDeeCart.load_configuration("spec/fixtures/test_config.yml")
  
    nori_options = {
      :strip_namespaces     => true,
      :convert_tags_to      => lambda { |tag| tag.snakecase.to_sym },
      :advanced_typecasting => true,
      :parser               => :nokogiri
    }
    doc = File.read("spec/fixtures/getOrder.xml")
    @valid_hash = Nori.new(nori_options).parse(doc)[:get_orders_response][:order]
    @invalid_hash = {:invalid_attribute => true}
    @valid_order_with_invalid_member = Nori.new(nori_options).parse(doc)[:get_orders_response][:order]
    @valid_order_with_invalid_member[:shipping_information][:shipment] = {invalid_attr: true}
  }
  
  after(:all)  { savon.unmock! }

  describe "#new" do
    it "should accept a valid hash to constructor" do
      lambda {
        ThreeDeeCart::Order.new(@valid_hash)
      }.should_not raise_error
    end

    it "should not accept a hash with invalid order attribute" do
      lambda {
        ThreeDeeCart::Order.new(@invalid_hash)
      }.should raise_error(ThreeDeeCart::Exceptions::InvalidAttribute)
    end

    it "should not accept a constructor hash that fails on a nested attribute" do
      lambda {
        ThreeDeeCart::Order.new(@valid_order_with_invalid_member)
      }.should raise_error(ThreeDeeCart::Exceptions::InvalidAttribute)
    end
  end

  describe "ThreeDeeCart::Order#count" do
    it "should extract the right quantity from a valid response" do
      savon.expects(:get_order_count).with({message: {status: "test"}}).returns(File.read("spec/fixtures/getOrderCount.xml"))

      order_count = ThreeDeeCart::Order.count({status: "test"})
      order_count.should eq(474)
    end
  end

  describe "ThreeDeeCart::Order#status" do
    it "should extract the right status from a valid response" do
      savon.expects(:get_order_status).with({message: {invoiceNum: "test"}}).returns(File.read("spec/fixtures/getOrderStatus.xml"))
      order_status = ThreeDeeCart::Order.status({invoiceNum: "test"})
      order_status[:status_id].should eq("1")
      order_status[:status_text].should eq("New")
    end
  end

  describe "ThreeDeeCart#find" do
    it "should return a valid order for a valid request" do
      savon.expects(:get_order).with({message: {id: "test"}}).returns(File.read("spec/fixtures/getOrder.xml"))
      order = ThreeDeeCart::Order.find({id: "test"})
      order.total.should eq("1590")
    end
  end
end