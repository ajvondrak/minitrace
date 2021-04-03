# frozen_string_literal: true

require "test_helper"

class Minitrace::Processors::SamplingTest < Minitest::Test
  def before_setup
    super
    Minitrace.backend = Minitrace::Backend.new do
      use Minitrace::Processors::Sampling
      use Minitrace::Processors::Spy
    end
  end

  SEND = %w[
    send
    iow4KAFBl9u6lF4EYIcsFz60rXGvu7ph
    EgQMHtruEfqaqQqRs5nwaDXsegFGmB5n
    UnVVepVdyGIiwkHwofyva349tVu8QSDn
    rWuxi2uZmBEprBBpxLLFcKtXHA8bQkvJ
    EMSmscnxwfrkKd1s3hOJ9bL4zqT1uud5
    YiLx0WGJrQAge2cVoAcCscDDVidbH4uE
    DyGaS7rfQsMX0E6TD9yORqx7kJgUYvNR
    wtGa41YcFMR5CBNr79lTfRAFi6Vhr6UF
    UAnMARj5x7hkh9kwBiNRfs5aYDsbHKpw
    Aes1rgTLMNnlCkb9s6bH7iT5CbZTdxUw
    mv70SFwpAOHRZt4dmuw5n2lAsM1lOrcx
    i4nIu0VZMuh5hLrUm9w2kqNxcfYY7Y3a
  ].freeze

  def test_deterministic_send
    Minitrace.backend.mode(:head)

    SEND.each do |id|
      event = Minitrace::Event.new.add_fields(
        "sample_rate" => 2,
        "trace.trace_id" => id,
      )
      Minitrace.backend.process(event)
      assert { processed == [event] }
      processed.clear
    end
  end

  def test_always_send
    %i[head tail].each do |mode|
      Minitrace.backend.mode(mode)
      event = Minitrace::Event.new.add_fields(
        "sample_rate" => 1,
        "trace.trace_id" => SecureRandom.hex(16),
      )
      Minitrace.backend.process(event)
      assert { processed == [event] }
      processed.clear
    end
  end

  DROP = %w[
    drop
    4YeYygWjTZ41zOBKUoYUaSVxPGm78rdU
    8PV5LN1IGm5T0ZVIaakb218NvTEABNZz
    IjD0JHdQdDTwKusrbuiRO4NlFzbPotvg
    ADwiQogJGOS4X8dfIcidcfdT9fY2WpHC
    MjOCkn11liCYZspTAhdULMEfWJGMHvpK
    3AsMjnpTBawWv2AAPDxLjdxx4QYl9XXb
    sa2uMVNPiZLK52zzxlakCUXLaRNXddBz
    NYH9lkdbvXsiUFKwJtjSkQ1RzpHwWloK
    8AwzQeY5cudY8YUhwxm3UEP7Oos61RTY
    ADKWL3p5gloRYO3ptarTCbWUHo5JZi3j
    eh1LYTOfgISrZ54B7JbldEpvqVur57tv
    u5A1wEYax1kD9HBeIjwyNAoubDreCsZ6
    UqfewK2qFZqfJ619RKkRiZeYtO21ngX1
  ].freeze

  def test_deterministic_drop
    Minitrace.backend.mode(:head)

    DROP.each do |id|
      event = Minitrace::Event.new.add_fields(
        "sample_rate" => 2,
        "trace.trace_id" => id,
      )
      Minitrace.backend.process(event)
      assert { processed.empty? }
    end
  end

  def test_always_drop
    %i[head tail].each do |mode|
      Minitrace.backend.mode(mode)
      event = Minitrace::Event.new.add_fields(
        "sample_rate" => 0,
        "trace.trace_id" => SecureRandom.hex(16),
      )
      Minitrace.backend.process(event)
      assert { processed.empty? }
      processed.clear
    end
  end

  def test_nondeterminism
    Minitrace.backend.mode(:tail)
    seed = srand(0)
    event = Minitrace::Event.new.add_fields(
      "sample_rate" => 10,
      "trace.trace_id" => SecureRandom.hex(16),
    )
    10.times { Minitrace.backend.process(event) }
    assert { processed == [event] }
  ensure
    srand(seed)
  end
end
