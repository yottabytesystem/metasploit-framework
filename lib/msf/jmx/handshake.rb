# -*- coding: binary -*-

module Msf
  module Jmx
    module Handshake
      def handshake_stream(id)
        stream = Rex::Java::Serialization::Model::Stream.new

        block_data = Rex::Java::Serialization::Model::BlockData.new
        block_data.contents = id + "\xff\xff\xff\xff\xf0\xe0\x74\xea\xad\x0c\xae\xa8"
        block_data.length = block_data.contents.length

        stream.contents << block_data

        if datastore['USERNAME']
          username = datastore['USERNAME']
          password = datastore['PASSWORD'] || ''

          stream.contents << auth_array_stream(username, password)
        else
          stream.contents << Rex::Java::Serialization::Model::NullReference.new
        end

        stream
      end

      def auth_array_stream(username, password)
        auth_array_class_desc = Rex::Java::Serialization::Model::NewClassDesc.new
        auth_array_class_desc.class_name = Rex::Java::Serialization::Model::Utf.new(nil, '[Ljava.lang.String;')
        auth_array_class_desc.serial_version = 0xadd256e7e91d7b47
        auth_array_class_desc.flags = 2
        auth_array_class_desc.fields = []
        auth_array_class_desc.class_annotation = Rex::Java::Serialization::Model::Annotation.new
        auth_array_class_desc.class_annotation.contents = [
          Rex::Java::Serialization::Model::NullReference.new,
          Rex::Java::Serialization::Model::EndBlockData.new
        ]
        auth_array_class_desc.super_class = Rex::Java::Serialization::Model::ClassDesc.new
        auth_array_class_desc.super_class.description = Rex::Java::Serialization::Model::NullReference.new

        auth_array = Rex::Java::Serialization::Model::NewArray.new
        auth_array.array_description = Rex::Java::Serialization::Model::ClassDesc.new
        auth_array.array_description.description = auth_array_class_desc
        auth_array.type = 'java.lang.String;'
        auth_array.values = [
          Rex::Java::Serialization::Model::Utf.new(nil, username),
          Rex::Java::Serialization::Model::Utf.new(nil, password)
        ]

        auth_array
      end

      def extract_rmi_connection_stub(block_data)
        data_io = StringIO.new(block_data.contents)

        ref = extract_string(data_io)
        return nil unless ref && ref == 'UnicastRef'

        address = extract_string(data_io)
        return nil unless address

        port = extract_int(data_io)
        return nil unless port

        id = data_io.read

        { address: address, port: port, :id => id }
      end
    end
  end
end
