# -*- coding: utf-8 -*-
require 'spec_helper'
require 'fileutils'

describe Ccp::Persistent::File do
  def db; Pathname("tmp/spec/ccp/persistent/json/db.json"); end

  before do
    FileUtils.rm_rf(db)
  end

  describe ".ext" do
    it "should return ''" do
      Ccp::Persistent::File.ext.should == ''
    end
  end

  describe "#path" do
    it "should return the given source if its ext is json" do
      kvs = Ccp::Persistent::File.new("tmp/foo.json", :json)
      kvs.path.to_s.should == "tmp/foo.json"
    end

    it "should return <given source>.json if its ext is not json" do
      kvs = Ccp::Persistent::File.new("tmp/foo", :json)
      kvs.path.to_s.should == "tmp/foo.json"
    end
  end

  describe "#[]=" do
    it "should create a json file" do
      db.should_not exist
      kvs = Ccp::Persistent::File.new(db, :json)
      kvs["foo"] = "[1,2,3]"
      db.should exist
    end

    it "should write json data as hash" do
      kvs = Ccp::Persistent::File.new(db, :json)
      kvs["foo"] = "[1,2,3]"
      db.read{}.should == '{"foo":"[1,2,3]"}'
    end

    it "should convert key to string" do
      kvs = Ccp::Persistent::File.new(db, :json)
      kvs[:foo] = "[1,2,3]"
      db.read{}.should == '{"foo":"[1,2,3]"}'
    end
  end

  describe "#load!" do
    it "should raise NotFound if not exists" do
      kvs = Ccp::Persistent::File.new(db, :json)
      lambda {
        kvs.load!("foo")
      }.should raise_error(Ccp::Persistent::NotFound)
    end

    it "should fetch data if exists" do
      db.open("w+"){|f| f.print(JSON.dump({"foo" => 1}))}
      kvs = Ccp::Persistent::File.new(db, :json)
      kvs.load!("foo").should == 1
    end

    it "should convert key to string" do
      db.open("w+"){|f| f.print(JSON.dump({"foo" => 1}))}
      kvs = Ccp::Persistent::File.new(db, :json)
      kvs.load!(:foo).should == 1
    end
  end

  describe "#load" do
    it "should return nil if not exists" do
      kvs = Ccp::Persistent::File.new(db, :json)
      kvs.load("foo2").should == nil
    end

    it "should fetch data if exists" do
      db.open("w+"){|f| f.print(JSON.dump({"foo" => 1}))}
      kvs = Ccp::Persistent::File.new(db, :json)
      kvs.load("foo").should == 1
    end

    it "should convert key to string" do
      db.open("w+"){|f| f.print(JSON.dump({"foo" => 1}))}
      kvs = Ccp::Persistent::File.new(db, :json)
      kvs.load(:foo).should == 1
    end
  end

  describe "#[]" do
    it "should fetch data if exists" do
      db.open("w+"){|f| f.print(JSON.dump({"foo" => 1}))}
      kvs = Ccp::Persistent::File.new(db, :json)
      kvs.load!(:foo).should == 1
    end

    it "should raise NotFound if not exists" do
      kvs = Ccp::Persistent::File.new(db, :json)
      lambda {
        kvs.load!(:foo)
      }.should raise_error(Ccp::Persistent::NotFound)
    end
  end

  describe "#read" do
    it "should fetch all data if exists" do
      db.open("w+"){|f| f.print(JSON.dump({"foo" => 1, "bar" => 2}))}
      kvs = Ccp::Persistent::File.new(db, :json)
      kvs.read.should == {"foo" =>1, "bar" =>2}
    end

    it "should raise NotFound if the path doesn't exist" do
      kvs = Ccp::Persistent::File.new(db + "no-such-file", :json)
      kvs.read.should == {}
    end
  end

  describe "#read!" do
    it "should fetch all data if exists" do
      db.open("w+"){|f| f.print(JSON.dump({"foo" => 1, "bar" => 2}))}
      kvs = Ccp::Persistent::File.new(db, :json)
      kvs.read!.should == {"foo" =>1, "bar" =>2}
    end

    it "should raise NotFound if the path doesn't exist" do
      kvs = Ccp::Persistent::File.new(db + "no-such-file", :json)
      lambda {
        kvs.read!
      }.should raise_error(Ccp::Persistent::NotFound)
    end
  end

  describe "#keys" do
    it "should return a sorted array of key names filtered by given ext" do
      db.open("w+"){|f| f.print(JSON.dump({"foo" => 1, "bar" => "xxx"}))}
      kvs = Ccp::Persistent::File.new(db, :json)
      kvs.keys.should == ["bar", "foo"]
    end

    it "should raise NotFound if the path doesn't exist" do
      kvs = Ccp::Persistent::File.new(db + "no-such-file", :json)
      lambda {
        kvs.keys
      }.should raise_error(Ccp::Persistent::NotFound)
    end
  end

  describe "#truncate" do
    it "should delete its db file" do
      db.open("w+"){|f| f.print(JSON.dump({"foo" => 1}))}
      db.should exist

      kvs = Ccp::Persistent::File.new(db, :json)
      kvs.truncate
      db.should_not exist      
    end
  end

  context "(:json)" do
    def db1; Pathname("tmp/spec/ccp/persistent/file/db1.json"); end
    def db2; Pathname("tmp/spec/ccp/persistent/file/db2.json"); end

    before do
      FileUtils.rm_rf(db1)
      FileUtils.rm_rf(db2)
    end

    it "should save data into storage and load it" do
      kvs = Ccp::Persistent::File.new(db1, :json)
      kvs[:foo] = "[1,2,3]"

      FileUtils.mv(db1, db2)
      kvs = Ccp::Persistent::File.new(db2, :json)
      kvs[:foo].should == "[1,2,3]"
    end
  end

  context "(:msgpack)" do
    def db1; Pathname("tmp/spec/ccp/persistent/file/db1.msgpack"); end
    def db2; Pathname("tmp/spec/ccp/persistent/file/db2.msgpack"); end

    before do
      FileUtils.rm_rf(db1)
      FileUtils.rm_rf(db2)
    end

    it "should save data into storage and load it" do
      kvs = Ccp::Persistent::File.new(db1, :msgpack)
      kvs[:flag] = [false, [], true, 1.2]

      FileUtils.mv(db1, db2)
      kvs = Ccp::Persistent::File.new(db2, :msgpack)
      kvs[:flag].should == [false, [], true, 1.2]
    end
  end
end
