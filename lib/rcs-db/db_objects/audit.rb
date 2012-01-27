require 'mongoid'

#module RCS
#module DB

class Audit
  include Mongoid::Document
  
  field :time, type: Integer
  field :actor, type: String
  field :action, type: String
  field :user_name, type: String
  field :group_name, type: String
  field :operation_name, type: String
  field :target_name, type: String
  field :agent_name, type: String
  field :desc, type: String
  
  index :time
  index :actor
  index :action
  index :user_name
  index :group_name
  index :operation_name
  index :target_name
  index :agent_name
  
  store_in :audit

  def self.filter(filter, start_index = nil, num_items = nil)
    filter_hash = {}

    # date filters must be treated separately
    if filter.has_key? 'from' and filter.has_key? 'to'
      filter_hash[:time.gte] = filter.delete('from')
      filter_hash[:time.lte] = filter.delete('to')
      #trace :debug, "Filtering date from #{filter['from']} to #{filter['to']}."
    end

    # desc filters must be handled as a regexp
    if filter.has_key? 'desc'
      #trace :debug, "Filtering description by keywork '#{filter['desc']}'."
      filter_hash[:desc] = Regexp.new(filter.delete('desc'), true)
    end

    # copy remaining filtering criteria (if any)
    filtering = Audit
    filter.each_key do |k|
      filtering = filtering.any_in(k.to_sym => filter[k])
    end

    # paging
    unless start_index.nil? or num_items.nil?
      #trace :debug, "Querying with filter #{filter_hash}."
      query = filtering.where(filter_hash).order_by([[:time, :asc]]).skip(start_index).limit(num_items)
    else
      # without paging, return everything
      query = filtering.where(filter_hash).order_by([[:time, :asc]])
    end

    return query
  end

  def self.field_names
    column_names = Audit.fields.keys
    column_names.delete('_type') if fields.has_key? '_type'
    return column_names
  end

  def to_flat_array
    column_names = Audit.field_names
    
    flat_array = []
    column_names.each do |name|
      value = (self.attributes[name].nil? ? "" : self.attributes[name].to_s)
      
      case name
        when 'time'
          value = Time.at(value.to_i).getutc.to_s
      end
      
      flat_array << value
    end
    
    return flat_array
  end
end

class AuditFilters
  include Mongoid::Document
    
  field :actor, type: Array
  field :action, type: Array
  field :user_name, type: Array
  field :group_name, type: Array
  field :operation_name, type: Array
  field :target_name, type: Array
  field :agent_name, type: Array
  
  store_in :audit_filters
end

#end # ::DB
#end # ::RCS