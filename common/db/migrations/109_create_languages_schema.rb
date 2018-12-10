require_relative 'utils'

def create_language_record_from_language_id(record_type, dataset, language_id)

  language_enum = self[:enumeration].filter(:name => 'language_iso639_2').get(:id)
  language_value = self[:enumeration_value].filter( :enumeration_id => language_enum, :value => language_id).get(:id)

  dataset.each do |row|

    linked_record_id = self[record_type].filter(:id => row[:id]).get(:id)
    language_value = self[record_type].filter(:language_id => row[:language_id]).get(:language_id)

    self[:language].insert(
                          :json_schema_version => row[:json_schema_version],
                          :language_id => language_value,
                          "#{record_type}_id" => linked_record_id,
                          :create_time => row[:create_time],
                          :system_mtime => row[:system_mtime],
                          :user_mtime => row[:user_mtime]
                        )

  end
end

Sequel.migration do
  up do

    create_table(:language) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :archival_object_id, :null => true
      Integer :resource_id, :null => true
      Integer :digital_object_id, :null => true
      Integer :digital_object_component_id, :null => true

      DynamicEnum :language_id, :null => true
      DynamicEnum :script_id, :null => true

      TextField :note, :null => true

      apply_mtime_columns
    end

    alter_table(:language) do
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
    end

    create_editable_enum('language_script', ["Adlm", "Afak", "Aghb", "Ahom", "Arab", "Aran", "Armi", "Armn", "Avst", "Bali", "Bamu", "Bass", "Batk", "Beng", "Bhks", "Blis", "Bopo", "Brah", "Brai", "Bugi", "Buhd", "Cakm", "Cans", "Cari", "Cham", "Cher", "Cirt", "Copt", "Cpmn", "Cprt", "Cyrl", "Cyrs", "Deva", "Dogr", "Dsrt", "Dupl", "Egyd", "Egyh", "Egyp", "Elba", "Elym", "Ethi", "Geok", "Geor", "Glag", "Gong", "Gonm", "Goth", "Gran", "Grek", "Gujr", "Guru", "Hanb", "Hang", "Hani", "Hano", "Hans", "Hant", "Hatr", "Hebr", "Hira", "Hluw", "Hmng", "Hmnp", "Hrkt", "Hung", "Inds", "Ital", "Jamo", "Java", "Jpan", "Jurc", "Kali", "Kana", "Khar", "Khmr", "Khoj", "Kitl", "Kits", "Knda", "Kore", "Kpel", "Kthi", "Lana", "Laoo", "Latf", "Latg", "Latn", "Leke", "Lepc", "Limb", "Lina", "Linb", "Lisu", "Loma", "Lyci", "Lydi", "Mahj", "Maka", "Mand", "Mani", "Marc", "Maya", "Medf", "Mend", "Merc", "Mero", "Mlym", "Modi", "Mong", "Moon", "Mroo", "Mtei", "Mult", "Mymr", "Nand", "Narb", "Nbat", "Newa", "Nkdb", "Nkgb", "Nkoo", "Nshu", "Ogam", "Olck", "Orkh", "Orya", "Osge", "Osma", "Palm", "Pauc", "Perm", "Phag", "Phli", "Phlp", "Phlv", "Phnx", "Plrd", "Piqd", "Prti", "Qaaa", "Qabx", "Rjng", "Rohg", "Roro", "Runr", "Samr", "Sara", "Sarb", "Saur", "Sgnw", "Shaw", "Shrd", "Shui", "Sidd", "Sind", "Sinh", "Sogd", "Sogo", "Sora", "Soyo", "Sund", "Sylo", "Syrc", "Syre", "Syrj", "Syrn", "Tagb", "Takr", "Tale", "Talu", "Taml", "Tang", "Tavt", "Telu", "Teng", "Tfng", "Tglg", "Thaa", "Thai", "Tibt", "Tirh", "Ugar", "Vaii", "Visp", "Wara", "Wcho", "Wole", "Xpeo", "Xsux", "Yiii", "Zanb", "Zinh", "Zmth", "Zsye", "Zsym", "Zxxx", "Zyyy", "Zzzz"])

    # take all values from language_id and turn them into language sub-records
    language_enum = self[:enumeration].filter(:name => 'language_iso639_2').get(:id)

    create_language_record_from_language_id(:resource, self[:resource].filter( Sequel.~(:language_id => nil)), self[:enumeration_value].filter( :enumeration_id => language_enum).get(:id))

    create_language_record_from_language_id(:archival_object, self[:archival_object].filter( Sequel.~(:language_id => nil)), self[:enumeration_value].filter( :enumeration_id => language_enum).get(:id))
    #
    create_language_record_from_language_id(:digital_object, self[:digital_object].filter( Sequel.~(:language_id => nil)), self[:enumeration_value].filter( :enumeration_id => language_enum).get(:id))

    create_language_record_from_language_id(:digital_object_component, self[:digital_object_component].filter( Sequel.~(:language_id => nil)), self[:enumeration_value].filter( :enumeration_id => language_enum).get(:id))

    # Drop old language_id column
    [:resource, :archival_object, :digital_object, :digital_object_component].each do |record|
      alter_table(record) do
        drop_foreign_key(:language_id)
      end
    end

    # Update Language of Description columns
    alter_table(:resource) do
      rename_column(:finding_aid_language, :finding_aid_language_note)
      set_column_type(:finding_aid_language_note, 'text')
      add_column(:finding_aid_language_id, :integer, :null => true)
      add_column(:finding_aid_script_id, :integer, :null => true)
    end

  end
end
