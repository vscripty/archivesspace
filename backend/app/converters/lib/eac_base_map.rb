module EACBaseMap
  def EAC_BASE_MAP(import_events = false)
    {
      # AGENT PERSON
      "//eac-cpf//cpfDescription[child::identity/child::entityType='person']" => {
        :obj => :agent_person,
        :map => agent_person_base(import_events)
      },
      # AGENT CORPORATE ENTITY
      "//eac-cpf//cpfDescription[child::identity/child::entityType='corporateBody']" => {
        :obj => :agent_corporate_entity,
        :map => agent_corporate_entity_base(import_events)
      },
      # AGENT FAMILY
      "//eac-cpf//cpfDescription[child::identity/child::entityType='family']" => {
        :obj => :agent_family,
        :map => agent_family_base(import_events)
      }
    }
  end

  # agent person name attrs, followed by agent subrecs common to all types
  def agent_person_base(import_events)
    {
      '//identity/nameEntry' => agent_person_name_map(:name_person, :names),
      '//identity/nameEntryParallel/nameEntry[1]' => agent_person_name_with_parallel_map(:name_person, :names),
      "//localDescriptions/localDescription[@localType='gender']" => agent_person_gender_map
      # "//relations/cpfRelation" => related_agent_map,
    }.merge(base_map_subfields(import_events))
  end

  # agent corporate name attrs, followed by agent subrecs common to all types
  def agent_corporate_entity_base(import_events)
    {
      '//identity/nameEntry' => agent_corporate_entity_name_map(:name_corporate_entity, :names),
      '//identity/nameEntryParallel/nameEntry[1]' => agent_corporate_entity_name_with_parallel_map(:name_corporate_entity, :names),
      '//eac-cpf//mandates/mandate' => agent_mandate_note_map,
      '//eac-cpf//legalStatuses/legalStatus' => agent_legal_status_note_map,
      '//eac-cpf//structureOrGenealogy' => agent_structure_note_map
    }.merge(base_map_subfields(import_events))
  end

  # agent family name attrs, followed by agent subrecs common to all types
  def agent_family_base(import_events)
    {
      '//identity/nameEntry' => agent_family_name_map(:name_family, :names),
      '//identity/nameEntryParallel/nameEntry[1]' => agent_family_name_with_parallel_map(:name_family, :names),
      '//eac-cpf//structureOrGenealogy' => agent_structure_note_map
    }.merge(base_map_subfields(import_events))
  end

  # These fields are common to all agent types and imported the same way
  def base_map_subfields(import_events)
    h = {
      '//eac-cpf//control/recordId' => agent_record_identifiers_map,
      '//eac-cpf//control/otherRecordId' => agent_other_record_identifiers_map,
      '//eac-cpf//control' => agent_record_control_map,
      '//eac-cpf/control/conventionDeclaration' => agent_conventions_declaration_map,
      '//eac-cpf/control/sources/source' => agent_sources_map,
      '//eac-cpf/cpfDescription/identity/entityId' => agent_identifier_map,
      '//eac-cpf/cpfDescription/description/existDates//date' => agent_date_single_map('existence', :dates_of_existence),
      '//eac-cpf/cpfDescription/description/existDates//dateRange' => agent_date_range_map('existence', :dates_of_existence),
      '//places/place' => agent_place_map,
      '//occupations/occupation' => agent_occupation_map,
      '//functions/function' => agent_function_map,
      "//localDescriptions/localDescription[@localType='associatedSubject']" => agent_topic_map,
      '//eac-cpf//biogHist' => agent_bioghist_note_map,
      '//eac-cpf//generalContext' => agent_general_context_note_map,
      '//eac-cpf/cpfDescription/alternativeSet/setComponent' => agent_set_component_map,
      '//languagesUsed/languageUsed' => agent_languages_map,
      '//relations/resourceRelation' => related_resource_map
    }

    if import_events
      h.merge!({
        '//eac-cpf/control/maintenanceHistory/maintenanceEvent' => agent_maintenance_history_map
      })
    end

    h
  end

  def agent_person_name_map(obj, rel)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_person_name_components_map,
      :defaults => {
        :source => 'local',
        :rules => 'local',
        :primary_name => 'primary name',
        :name_order => 'direct'
      }
    }
  end

  def agent_person_name_with_parallel_map(obj, rel)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_person_name_components_map.merge({
        'following-sibling::nameEntry' => agent_person_name_map(:parallel_name_person, :parallel_names)
      }),
      :defaults => {
        :source => 'local',
        :rules => 'local',
        :primary_name => 'primary name',
        :name_order => 'direct'
      }
    }
  end

  def agent_corporate_entity_name_map(obj, rel)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_corporate_entity_name_components_map,
      :defaults => {
        :source => 'local',
        :rules => 'local',
        :primary_name => 'primary name',
        :name_order => 'direct'
      }
    }
  end

  def agent_corporate_entity_name_with_parallel_map(obj, rel)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_corporate_entity_name_components_map.merge({
        'following-sibling::nameEntry' => agent_corporate_entity_name_map(:parallel_name_corporate_entity, :parallel_names)
      }),
      :defaults => {
        :source => 'local',
        :rules => 'local',
        :primary_name => 'primary name',
        :name_order => 'direct'
      }
    }
  end

  def agent_family_name_map(obj, rel)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_family_name_components_map,
      :defaults => {
        :source => 'local',
        :rules => 'local',
        :primary_name => 'primary name',
        :name_order => 'direct'
      }
    }
  end

  def agent_family_name_with_parallel_map(obj, rel)
    {
      :obj => obj,
      :rel => rel,
      :map => agent_family_name_components_map.merge({
        'following-sibling::nameEntry' => agent_family_name_map(:parallel_name_family, :parallel_names)
      }),
      :defaults => {
        :source => 'local',
        :rules => 'local',
        :primary_name => 'primary name',
        :name_order => 'direct'
      }
    }
  end

  def agent_person_name_components_map
    {
       'self::nameEntry[@lang]' => proc { |name, node|
         name[:language] = node.attr('lang')
       },
       'descendant::part[@lang]' => proc { |name, node|
         name[:language] = node.attr('lang')
       },
       'self::nameEntry[@scriptCode]' => proc { |name, node|
         name[:script] = node.attr('scriptCode')
       },
       'self::nameEntry[@transliteration]' => proc { |name, node|
         name[:transliteration] = node.attr('transliteration')
       },
       "descendant::part[@localType='prefix']" => proc { |name, node|
         val = node.inner_text
         name[:prefix] = val
       },
       "descendant::part[@localType='suffix']" => proc { |name, node|
         val = node.inner_text
         name[:suffix] = val
       },
       "descendant::part[@localType='title']" => proc { |name, node|
         val = node.inner_text
         name[:title] = val
       },
       "descendant::part[@localType='surname']" => proc { |name, node|
         val = node.inner_text
         name[:primary_name] = val
       },
       "descendant::part[@localType='forename']" => proc { |name, node|
         val = node.inner_text
         name[:rest_of_name] = val
       },
       "descendant::part[@localType='numeration']" => proc { |name, node|
         val = node.inner_text
         name[:number] = val
       },
       "descendant::part[@localType='fuller_form']" => proc { |name, node|
         val = node.inner_text
         name[:fuller_form] = val
       },
       "descendant::part[@localType='dates']" => proc { |name, node|
         val = node.inner_text
         name[:dates] = val
       },
       "descendant::part[@localType='qualifier']" => proc { |name, node|
         val = node.inner_text
         name[:qualifier] = val
       },
       'descendant::authorizedForm' => proc { |name, node|
         val = node.inner_text
         name[:source] = val
         name[:authorized] = true
       },
       'descendant::alternativeForm' => proc { |name, node|
         val = node.inner_text
         name[:source] = val
         name[:authorized] = false
       },
       'descendant::part[not(@localType)]' => proc { |name, node|
         val = node.inner_text
         name[:primary_name] = val
         name[:dates] = val.scan(/[0-9]{4}-[0-9]{4}/).flatten[0]
       }, # if localType attr is not defined, assume primary_name
       "descendant::part[not(@localType='prefix') and   not(@localType='prefix') and not(@localType='suffix') and   not(@localType='title')  and not(@localType='surname')  and   not(@localType='forename') and not(@localType='numeration') and   not(@localType='fuller_form') and not(@localType='dates') and   not(@localType='qualifier')]" => proc { |name, node|
         val = node.inner_text
         name[:primary_name] = val
         name[:dates] = val.scan(/[0-9]{4}-[0-9]{4}/).flatten[0]
       }, # if localType attr is something else
       'descendant::useDates//date' => agent_date_single_map('usage', :use_dates),
       'descendant::useDates//dateRange' => agent_date_range_map('usage', :use_dates)
     }
  end

  def agent_corporate_entity_name_components_map
    {
      'self::nameEntry[@lang]' => proc { |name, node|
        name[:language] = node.attr('lang')
      },
      'descendant::part[@lang]' => proc { |name, node|
                                     name[:language] = node.attr('lang')
                                   },
      'self::nameEntry[@scriptCode]' => proc { |name, node|
        name[:script] = node.attr('scriptCode')
      },
      'self::nameEntry[@transliteration]' => proc { |name, node|
                                               name[:transliteration] = node.attr('transliteration')
                                             },
      "descendant::part[@localType='primary_name']" => proc { |name, node|
        val = node.inner_text
        name[:primary_name] = val
      },
      "descendant::part[@localType='subordinate_name_1']" => proc { |name, node|
        val = node.inner_text
        name[:subordinate_name_1] = val
      },
      "descendant::part[@localType='subordinate_name_2']" => proc { |name, node|
        val = node.inner_text
        name[:subordinate_name_2] = val
      },
      "descendant::part[@localType='numeration']" => proc { |name, node|
        val = node.inner_text
        name[:number] = val
      },
      "descendant::part[@localType='location']" => proc { |name, node|
        val = node.inner_text
        name[:location] = val
      },
      "descendant::part[@localType='dates']" => proc { |name, node|
        val = node.inner_text
        name[:dates] = val
      },
      "descendant::part[@localType='qualifier']" => proc { |name, node|
        val = node.inner_text
        name[:qualifier] = val
      },
      'descendant::authorizedForm' => proc { |name, node|
        val = node.inner_text
        name[:source] = val
        name[:authorized] = true
      },
      'descendant::alternativeForm' => proc { |name, node|
        val = node.inner_text
        name[:source] = val
        name[:authorized] = false
      },
      'descendant::part[not(@localType)]' => proc { |name, node|
        val = node.inner_text
        name[:primary_name] = val
        name[:dates] = val.scan(/[0-9]{4}-[0-9]{4}/).flatten[0]
      }, # if localType attr is not defined, assume primary_name
      "descendant::part[not(@localType='primary_name') and not(@localType='subordinate_name_1') and not(@localType='subordinate_name_2') and not(@localType='numeration') and not(@localType='location') and not(@localType='dates') and not(@localType='qualifier')]" => proc { |name, node|
        val = node.inner_text
        name[:primary_name] = val
        name[:dates] = val.scan(/[0-9]{4}-[0-9]{4}/).flatten[0]
      }, # if localType attr is something else
      'descendant::useDates//date' => agent_date_single_map('usage', :use_dates),
      'descendant::useDates//dateRange' => agent_date_range_map('usage', :use_dates)
    }
  end

  def agent_family_name_components_map
    {
      'self::nameEntry[@lang]' => proc { |name, node|
        name[:language] = node.attr('lang')
      },
      'descendant::part[@lang]' => proc { |name, node|
                                     name[:language] = node.attr('lang')
                                   },
      'self::nameEntry[@scriptCode]' => proc { |name, node|
        name[:script] = node.attr('scriptCode')
      },
      'self::nameEntry[@transliteration]' => proc { |name, node|
                                               name[:transliteration] = node.attr('transliteration')
                                             },
      "descendant::part[@localType='prefix']" => proc { |name, node|
        val = node.inner_text
        name[:prefix] = val
      },
      "descendant::part[@localType='surname']" => proc { |name, node|
        val = node.inner_text
        name[:family_name] = val
      },
      "descendant::part[@localType='family_type']" => proc { |name, node|
        val = node.inner_text
        name[:family_type] = val
      },
      "descendant::part[@localType='location']" => proc { |name, node|
        val = node.inner_text
        name[:location] = val
      },
      "descendant::part[@localType='dates']" => proc { |name, node|
        val = node.inner_text
        name[:dates] = val
      },
      "descendant::part[@localType='qualifier']" => proc { |name, node|
        val = node.inner_text
        name[:qualifier] = val
      },
      'descendant::authorizedForm' => proc { |name, node|
        val = node.inner_text
        name[:source] = val
        name[:authorized] = true
      },
      'descendant::alternativeForm' => proc { |name, node|
        val = node.inner_text
        name[:source] = val
        name[:authorized] = false
      },
      'descendant::part[not(@localType)]' => proc { |name, node|
        val = node.inner_text
        name[:family_name] = val
        name[:dates] = val.scan(/[0-9]{4}-[0-9]{4}/).flatten[0]
      }, # if localType attr is not defined, assume primary_name
      "descendant::part[not(@localType='prefix') and not(@localType='surname') and not(@localType='family_type') and not(@localType='location') and not(@localType='dates') and not(@localType='qualifier')]" => proc { |name, node|
        val = node.inner_text
        name[:family_name] = val
        name[:dates] = val.scan(/[0-9]{4}-[0-9]{4}/).flatten[0]
      }, # if localType attr is something else, assume primary_name
      'descendant::useDates//date' => agent_date_single_map('usage', :use_dates),
      'descendant::useDates//dateRange' => agent_date_range_map('usage', :use_dates)
    }
  end

  def agent_record_identifiers_map
    {
      :obj => :agent_record_identifier,
      :rel => :agent_record_identifiers,
      :map => {
        'self::recordId' => proc { |id, node|
          val = node.inner_text
          id[:record_identifier] = val
          id[:primary_identifier] = true
        }
      },
      :defaults => {
        :primary_identifier => true,
        :source => 'local'
      }
    }
  end

  def agent_other_record_identifiers_map
    {
      :obj => :agent_record_identifier,
      :rel => :agent_record_identifiers,
      :map => {
         'self::otherRecordId' => proc { |id, node|
                                    val = node.inner_text
                                    id[:record_identifier] = val
                                    id[:primary_identifier] = false
                                    id[:identifier_type] = node.attr('localType')
                                  }
      },
      :defaults => {
        :primary_identifier => false,
        :source => 'local'
      }
    }
  end

  def agent_record_control_map
    {
      :obj => :agent_record_control,
      :rel => :agent_record_controls,
      :map => {
        'descendant::maintenanceStatus' => proc { |arc, node|
          val = node.inner_text
          arc[:maintenance_status] = val
        },
        'descendant::maintenanceAgency/agencyCode' => proc { |arc, node|
          val = node.inner_text
          arc[:maintenance_agency] = val
        },
        'descendant::maintenanceAgency/agencyName' => proc { |arc, node|
          val = node.inner_text
          arc[:agency_name] = val
        },
        'descendant::maintenanceAgency/descriptiveNote' => proc { |arc, node|
          val = node.inner_text
          arc[:maintenance_agency_note] = val
        },
        'descendant::publicationStatus' => proc { |arc, node|
          val = node.inner_text
          arc[:publication_status] = val
        },
        'descendant::languageDeclaration/language' => proc { |arc, node|
          arc[:language] = node.attr('languageCode')
        },
        'descendant::languageDeclaration/script' => proc { |arc, node|
          arc[:script] = node.attr('scriptCode')
        },
        'descendant::languageDeclaration/descriptiveNote' => proc { |arc, node|
          val = node.inner_text
          arc[:language_note] = val
        }
      },
      :defaults => {
        :maintenance_status => 'new'
      }
    }
  end

  def agent_conventions_declaration_map
    {
      :obj => :agent_conventions_declaration,
      :rel => :agent_conventions_declarations,
      :map => {
        'descendant::abbreviation' => proc { |dec, node|
          val = node.inner_text.downcase
          dec[:name_rule] = val
        },
        'descendant::citation' => proc { |dec, node|
          val = node.inner_text
          dec[:citation] = val.nil? || val.length == 0 ? 'citation' : val
          dec[:file_uri] = node.attr('href')
          dec[:file_version_xlink_actuate_attribute] = node.attr('actuate')
          dec[:file_version_xlink_show_attribute] = node.attr('show')
          dec[:xlink_title_attribute] = node.attr('title')
          dec[:xlink_role_attribute] = node.attr('role')
          dec[:xlink_arcrole_attribute] = node.attr('arcrole')
          dec[:last_verified_date] = node.attr('lastDateTimeVerified')
        },
        'descendant::descriptiveNote' => proc { |dec, node|
          val = node.inner_text
          val = val.empty? ? 'No descriptive note specified' : val
          dec[:descriptive_note] = val
        }
      },
      :defaults => {
        :citation => 'citation',
        :name_rule => 'local',
        :descriptive_note => 'No descriptive note specified'
      }
    }
  end

  def agent_set_component_map
    {
      :obj => :agent_alternate_set,
      :rel => :agent_alternate_sets,
      :map => {
        'self::setComponent' => proc { |as, node|
          as[:file_uri] = node.attr('href')
          as[:file_version_xlink_actuate_attribute] = node.attr('actuate')
          as[:file_version_xlink_show_attribute] = node.attr('show')
          as[:xlink_title_attribute] = node.attr('title')
          as[:xlink_role_attribute] = node.attr('role')
          as[:xlink_arcrole_attribute] = node.attr('arcrole')
          as[:last_verified_date] = node.attr('lastDateTimeVerified')
        },
        'descendant::descriptiveNote' => proc { |as, node|
          val = node.inner_text
          val = val.empty? ? 'No descriptive note specified' : val
          as[:descriptive_note] = val
        },
        'descendant::componentEntry' => proc { |as, node|
          val = node.inner_text
          as[:set_component] = val
        }
      },
      :defaults => {
        :descriptive_note => 'No descriptive note specified'
      }
    }
  end

  def agent_maintenance_history_map
    {
      :obj => :agent_maintenance_history,
      :rel => :agent_maintenance_histories,
      :map => {
        'descendant::eventType' => proc { |me, node|
          val = node.inner_text.downcase
          me[:maintenance_event_type] = val
        },
        'descendant::agentType' => proc { |me, node|
          val = node.inner_text
          me[:maintenance_agent_type] = val
        },
        'descendant::agent' => proc { |me, node|
          val = node.inner_text
          me[:agent] = val
        },
        'descendant::eventDateTime' => proc { |me, node|
          val = node.attr('standardDateTime')
          val2 = node.inner_text

          me[:event_date] = val
          me[:event_date] = val2 if val.nil?
        },
        'descendant::eventDescription' => proc { |me, node|
          val = node.inner_text
          val = val.empty? ? 'No descriptive note specified' : val
          me[:descriptive_note] = val
        }
      },
      :defaults => {
        :descriptive_note => 'No descriptive note specified'
      }
    }
  end

  def agent_sources_map
    {
      :obj => :agent_sources,
      :rel => :agent_sources,
      :map => {
        'self::source' => proc { |s, node|
          s[:file_uri] = node.attr('href')
          s[:file_version_xlink_actuate_attribute] = node.attr('actuate')
          s[:file_version_xlink_show_attribute] = node.attr('show')
          s[:xlink_title_attribute] = node.attr('title')
          s[:xlink_role_attribute] = node.attr('role')
          s[:xlink_arcrole_attribute] = node.attr('arcrole')
          s[:last_verified_date] = node.attr('lastDateTimeVerified')
        },
        'descendant::sourceEntry' => proc { |s, node|
          val = node.inner_text
          s[:source_entry] = val
        },
        'descendant::descriptiveNote' => proc { |s, node|
          val = node.inner_text
          val = val.empty? ? 'No descriptive note specified' : val
          s[:descriptive_note] = val
        }
      },
      :defaults => {
        :descriptive_note => 'No descriptive note specified'
      }
    }
  end

  def agent_identifier_map
    {
      :obj => :agent_identifier,
      :rel => :agent_identifiers,
      :map => {
        'self::entityId' => proc { |id, node|
          val = node.inner_text
          id[:entity_identifier] = val
          id[:identifier_type] = node.attr('localType')
        }
      },
      :defaults => {
      }
    }
  end

  def agent_date_single_map(label = nil, rel = :dates)
    {
      :obj => :structured_date_label,
      :rel => rel,
      :map => {
        'self::date' => proc { |date, node|
          exp = node.inner_text
          role = 'begin'
          type = 'single'

          label = node.attr('localType') if label.nil?
          label = 'other' if label.nil?

          if node.attr('standardDate')
            std = node.attr('standardDate')

            std_type = if node.attr('notBefore')
                         node.attr('notBefore')
                       elsif node.attr('notAfter')
                         node.attr('notAfter')
                       end
          else
            std = nil
            std_type = nil
          end

          sds = ASpaceImport::JSONModel(:structured_date_single).new({
            :date_role => role,
            :date_expression => exp,
            :date_standardized => std,
            :date_standardized_type => std_type
          })

          date[:date_label] = label
          date[:date_type_structured] = type
          date[:structured_date_single] = sds
        }
      },
      :defaults => {
      }
    }
  end

  def agent_date_range_map(label = nil, rel = :dates)
    {
      :obj => :structured_date_label,
      :rel => rel,
      :map => {
        'self::dateRange' => proc { |date, node|
          label = node.attr('localType') if label.nil?
          label = 'other' if label.nil?

          type = 'range'

          begin_node = node.search('./fromDate')
          end_node = node.search('./toDate')

          begin_exp = begin_node.inner_text
          end_exp = end_node.inner_text

          begin_std = begin_node.attr('standardDate') ? begin_node.attr('standardDate').value : nil
          end_std = end_node.attr('standardDate') ? end_node.attr('standardDate').value : nil

          begin_std_type = if begin_std
                             if begin_node.attr('notBefore')
                               begin_node.attr('notBefore').value
                             elsif begin_node.attr('notAfter')
                               begin_node.attr('notAfter').value
                             end
                           end

          end_std_type = if end_std
                           if end_node.attr('notBefore')
                             end_node.attr('notBefore').value
                           elsif end_node.attr('notAfter')
                             end_node.attr('notAfter').value
                           end
                         end

          sdr = ASpaceImport::JSONModel(:structured_date_range).new({
            :begin_date_expression => begin_exp,
            :begin_date_standardized => begin_std,
            :begin_date_standardized_type => begin_std_type,
            :end_date_expression => end_exp,
            :end_date_standardized => end_std,
            :end_date_standardized_type => end_std_type
          })

          date[:date_label] = label
          date[:date_type_structured] = type
          date[:structured_date_range] = sdr
        }
      },
      :defaults => {
      }
    }
  end

  def agent_person_gender_map
    {
      :obj => :agent_gender,
      :rel => :agent_genders,
      :map => {
        'descendant::term' => proc { |gender, node|
          val = node.inner_text
          gender[:gender] = val
        },
        'descendant::date' => agent_date_single_map,
        'descendant::dateRange' => agent_date_range_map,
        'descendant::descriptiveNote' => agent_text_note_map('self::descriptiveNote')
      },
      :defaults => {
      }
    }
  end

  def agent_place_map
    {
    :obj => :agent_place,
    :rel => :agent_places,
    :map => {
      'descendant::placeRole' => proc { |apl, node|
        val = node.inner_text
        apl[:place_role] = val
      },

      'descendant::placeEntry' => subject_map('self::placeEntry',
                                              subject_terms_map('geographic'),
                                              subject_source_map),

      'descendant::date' => agent_date_single_map,

      'descendant::dateRange' => agent_date_range_map,

      'descendant::descriptiveNote' => agent_text_note_map('self::descriptiveNote'),

      'descendant::citation' => agent_citation_note_map('self::citation')
      }
    }
  end

  def agent_occupation_map
    {
    :obj => :agent_occupation,
    :rel => :agent_occupations,
    :map => {

      'descendant::term' => subject_map('self::term',
                                        subject_terms_map('occupation'),
                                        subject_source_map),

      'descendant::date' => agent_date_single_map,

      'descendant::dateRange' => agent_date_range_map,

      'descendant::descriptiveNote' => agent_text_note_map('self::descriptiveNote'),

      'descendant::citation' => agent_citation_note_map('self::citation')
      }
    }
  end

  def agent_function_map
    {
    :obj => :agent_function,
    :rel => :agent_functions,
    :map => {

      'descendant::term' => subject_map('self::term',
                                        subject_terms_map('function'),
                                        subject_source_map),

      'descendant::date' => agent_date_single_map,

      'descendant::dateRange' => agent_date_range_map,

      'descendant::descriptiveNote' => agent_text_note_map('self::descriptiveNote'),

      'descendant::citation' => agent_citation_note_map('self::citation')
      }
    }
  end

  def agent_topic_map
    {
    :obj => :agent_topic,
    :rel => :agent_topics,
    :map => {

      'descendant::term' => subject_map('self::term',
                                        subject_terms_map('topical'),
                                        subject_source_map),

      'descendant::date' => agent_date_single_map,

      'descendant::dateRange' => agent_date_range_map,

      'descendant::descriptiveNote' => agent_text_note_map('self::descriptiveNote'),

      'descendant::citation' => agent_citation_note_map('self::citation')
      }
    }
  end

  def agent_languages_map
    {
     :obj => :used_language,
     :rel => :used_languages,
     :map => {
       'descendant::language' => proc { |lang, node|
         lang[:language] = node.attr('languageCode')
       },
       'descendant::script' => proc { |lang, node|
         lang[:script] = node.attr('scriptCode')
       },
       'descendant::descriptiveNote' => agent_text_note_map('self::descriptiveNote')
     }
   }
  end

  # "creatorOf" or "subjectOf" or "other"
  def related_resource_map
    {
      :obj => :agent_resource,
      :rel => :agent_resources,
      :map => {
        'self::resourceRelation' => proc { |rr, node|
          rr[:file_uri] = node.attr('href')
          rr[:file_version_xlink_actuate_attribute] = node.attr('actuate')
          rr[:file_version_xlink_show_attribute] = node.attr('show')
          rr[:xlink_title_attribute] = node.attr('title')
          rr[:xlink_role_attribute] = node.attr('role')
          rr[:xlink_arcrole_attribute] = node.attr('arcrole')
          rr[:last_verified_date] = node.attr('lastDateTimeVerified')

          rr[:linked_agent_role] = if node.attr('resourceRelationType') == 'creatorOf'
                                     'creator'
                                   elsif node.attr('resourceRelationType') == 'subjectOf'
                                     'subject'
                                   else
                                     'source'
                                   end
        },
        'descendant::relationEntry' => proc { |rr, node|
          rr[:linked_resource] = node.inner_text
        },
        'descendant::descriptiveNote' => proc { |rr, node|
          rr[:linked_resource_description] = node.inner_text
        },
        'descendant::date' => agent_date_single_map,
        'descendant::dateRange' => agent_date_range_map
      },
      :defaults => {
      }
    }
  end

  def agent_bioghist_note_map
    {
      :obj => :note_bioghist,
      :rel => :notes,
      :map => {
        'self::biogHist' => proc { |note, node|
          note['subnotes'] << {
            'jsonmodel_type' => 'note_text',
            'content' => node.inner_text
          }
        }
      },
      :defaults => {
        :label => 'default label'
      }
    }
  end

  def agent_general_context_note_map
    {
      :obj => :note_general_context,
      :rel => :notes,
      :map => {
        'self::generalContext' => proc { |note, node|
          note['subnotes'] << {
            'jsonmodel_type' => 'note_text',
            'content' => node.inner_text
          }
        }
      },
      :defaults => {
        :label => 'default label'
      }
    }
  end

  def agent_structure_note_map
    {
      :obj => :note_structure_or_genealogy,
      :rel => :notes,
      :map => {
        'self::structureOrGenealogy' => proc { |note, node|
          note['subnotes'] << {
            'jsonmodel_type' => 'note_text',
            'content' => node.inner_text
          }
        }
      },
      :defaults => {
        :label => 'default label'
      }
    }
  end

  def agent_legal_status_note_map
    {
      :obj => :note_legal_status,
      :rel => :notes,
      :map => {
        'descendant::citation' => proc { |note, node|
          note['subnotes'] << {
            'jsonmodel_type' => 'note_citation',
            'content' => [node.inner_text]
          }
        },
        'descendant::descriptiveNote' => proc { |note, node|
          note['subnotes'] << {
            'jsonmodel_type' => 'note_text',
            'content' => node.inner_text
          }
        }
      },
      :defaults => {
        :label => 'default label'
      }
    }
  end

  def agent_mandate_note_map
    {
      :obj => :note_mandate,
      :rel => :notes,
      :map => {
        'descendant::citation' => proc { |note, node|
          note['subnotes'] << {
            'jsonmodel_type' => 'note_citation',
            'content' => [node.inner_text]
          }
        },
        'descendant::descriptiveNote' => proc { |note, node|
          note['subnotes'] << {
            'jsonmodel_type' => 'note_text',
            'content' => node.inner_text
          }
        }
      },
      :defaults => {
        :label => 'default label'
      }
    }
  end

  def agent_text_note_map(xpath, rel = :notes)
    {
      :obj => :note_text,
      :rel => rel,
      :map => {
        xpath => proc { |note, node|
          note.content = node.inner_text
        }
      },
      :defaults => {
      }
    }
  end

  def agent_citation_note_map(xpath, rel = :notes)
    {
      :obj => :note_citation,
      :rel => rel,
      :map => {
        xpath => proc { |note, node|
          note.content << node.inner_text
        }
      },
      :defaults => {
      }
    }
  end

  def subject_terms_map(term_type)
    proc { |node|
      [{ :term_type => term_type,
         :term => node.inner_text,
         :vocabulary => '/vocabularies/1' }]
    }
  end

  def subject_source_map
    proc { |node|
      node.attr('vocabularySource')
    }
  end

  # usually, rel will be :subjects, but in some cases it will be :places
  def subject_map(xpath, terms, source, rel = :subjects)
    {
      :obj => :subject,
      :rel => rel,
      :map => {
        xpath => proc { |subject, node|
          subject.publish = true
          subject.authority_id = node.attr('vocabularySource')
          subject.terms = terms.call(node)
          subject.source = source.call(node)
          subject.vocabulary = '/vocabularies/1'
        }
      },
      :defaults => {
        :source => 'Source not specified'
      }
    }
  end

  # CPF allowed values for relType attr:
  # {}"identity" or "hierarchical" or "hierarchical-parent" or "hierarchical-child" or "temporal" or "temporal-earlier" or "temporal-later" or "family" or "associative"
  def related_agent_map
    {
      :obj => :agent_relationship_associative,
      :rel => :related_agents,
      :map => {
        'self::cpfRelation' => proc { |ra, _node|
          ra.relator = 'is_associative_with'
        },
        'descendant::relationEntry' => related_agent_person_map
      },
      :defaults => {
      }
    }
  end

  def related_agent_person_map
    {
      :obj => :agent_person,
      :rel => :ref,
      :map => {
        'self::relationEntry' => proc { |ap, node|
          name_person = ASpaceImport::JSONModel(:name_person).new({
            :primary_name => node.inner_text,
            :name_order => 'direct'
          })
          ap.names = [name_person]
        }
      },
      :defaults => {
      }
    }
  end
end
