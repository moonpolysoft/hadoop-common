/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.hadoop.io.serializer.avro;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import org.apache.avro.Schema;
import org.apache.avro.io.BinaryDecoder;
import org.apache.avro.io.BinaryEncoder;
import org.apache.avro.io.DatumReader;
import org.apache.avro.io.DatumWriter;
import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.io.serializer.Deserializer;
import org.apache.hadoop.io.serializer.Serialization;
import org.apache.hadoop.io.serializer.Serializer;

/**
 * Base class for providing serialization to Avro types.
 */
public abstract class AvroSerialization<T> extends Configured 
                                        implements Serialization<T>{

  public Deserializer<T> getDeserializer(Class<T> c) {
    return new AvroDeserializer(c);
  }

  public Serializer<T> getSerializer(Class<T> c) {
    return new AvroSerializer(c);
  }

  /**
   * Return an Avro Schema instance for the given class.
   */
  protected abstract Schema getSchema(T t);

  /**
   * Create and return Avro DatumWriter for the given class.
   */
  protected abstract DatumWriter<T> getWriter(Class<T> clazz);

  /**
   * Create and return Avro DatumReader for the given class.
   */
  protected abstract DatumReader<T> getReader(Class<T> clazz);

  class AvroSerializer implements Serializer<T> {

    private DatumWriter<T> writer;
    private BinaryEncoder encoder;
    private OutputStream outStream;
    protected Class<T> clazz;

    AvroSerializer(Class<T> clazz) {
      writer = getWriter(clazz);
    }

    public void close() throws IOException {
      encoder.flush();
      outStream.close();
    }

    public void open(OutputStream out) throws IOException {
      outStream = out;
      encoder = new BinaryEncoder(out);
    }

    public void serialize(T t) throws IOException {
      writer.setSchema(getSchema(t));
      writer.write(t, encoder);
    }

  }

  class AvroDeserializer implements Deserializer<T> {

    private DatumReader<T> reader;
    private BinaryDecoder decoder;
    private InputStream inStream;

    AvroDeserializer(Class<T> clazz) {
      this.reader = getReader(clazz);
    }

    public void close() throws IOException {
      inStream.close();
    }

    public T deserialize(T t) throws IOException {
      return reader.read(t, decoder);
    }

    public void open(InputStream in) throws IOException {
      inStream = in;
      decoder = new BinaryDecoder(in);
    }

  }

}