module ITRP

class Cmd_traffic < Cmd 
	def initialize (e)
		super(e)
		@enabled_in_state = :counter
		@attach_cmd  = ''
		@trigger = 'traffic'
	end



    def enter(cmdline)

        patt = cmdline.scan(/traffic\s+(.*)/).flatten

		p patt 

		use_key = patt.empty? ? appstate(:cgkey)  : patt[0]

		# meter names 
		req =mk_request(TRP::Message::Command::COUNTER_GROUP_INFO_REQUEST,
						 :counter_group => @appenv.context_data[:cgguid],
						 :get_meter_info => true )

		colnames   = ["Timestamp"]
		get_response_zmq(@appenv.zmq_endpt,req) do |resp|
			  resp.group_details.each do |group_detail|
			  	group_detail.meters.each do |meter|
					colnames  <<  meter.name  
				end
			  end
		end


		req =TrisulRP::Protocol.mk_request(TRP::Message::Command::COUNTER_ITEM_REQUEST,
			 :counter_group => @appenv.context_data[:cgguid],
			 :key => TRP::KeyT.new( :label => use_key ),
			 :time_interval =>  appstate( :time_interval) ) 

		rows  = [] 

	
		TrisulRP::Protocol.get_response_zmq(@appenv.zmq_endpt,req) do |resp|
			  print "Counter Group = #{resp.stats.counter_group}\n"
			  print "Key           = #{resp.stats.key.key}\n"
			  print "Readable      = #{resp.stats.key.readable}\n"
			  print "Label         = #{resp.stats.key.label}\n"

			  tseries  = {}
			  resp.stats.meters.each do |meter|
				meter.values.each do |val|
					tseries[ val.ts.tv_sec ] ||= []
					tseries[ val.ts.tv_sec ]  << val.val 
				end
			  end


			  rows = []
			  tseries.each do |ts,valarr|
			  	rows << [ ts, valarr ].flatten 
			  end

			  table = Terminal::Table.new(:headings => colnames,  :rows => rows )
			  puts(table) 
		end

	end

end
end

