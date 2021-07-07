require AddressHelper
require AddressFormatting

time = fn ->
  for {_, data} = input_tuple <-
        AddressHelper.load_testcases_countries() do
    AddressFormatting.render(data)
  end
end

Benchee.run(%{
  "time" => time
},
 memory_time: 2
)
