require 'ffi'

module Puavo
    class ConfErr < FFI::Struct
        layout  :errnum, :int,
      :db_error, :int,
      :sys_errno, :int,
      :msg, [:char, 1024]
    end

    class ConfList < FFI::Struct
      layout :keys  , :pointer,
             :values, :pointer,
             :length, :size_t
    end

    class Conf
        class Error < StandardError
        end

        extend FFI::Library
        begin
            ffi_lib '/usr/local/lib/libpuavoconf.so'
        rescue LoadError
            ffi_lib '/usr/lib/libpuavoconf.so'
        end

        attach_function(:puavo_conf_open,
                        [:pointer, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_open_direct,
                        [:pointer, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_clear,
                        [:pointer, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_close,
                        [:pointer, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_set,
                        [:pointer, :string, :string, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_get,
                        [:pointer, :string, :pointer, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_get_all,
                        [:pointer, ConfList.by_ref, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_has_key,
                        [:pointer, :string, :pointer, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_add,
                        [:pointer, :string, :pointer, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_overwrite,
                        [:pointer, :string, :pointer, ConfErr.by_ref],
                        :int)
        attach_function(:puavo_conf_list_free,
                        [ConfList.by_ref],
                        :void)

        def initialize(direct=false)
            puavoconf_p = FFI::MemoryPointer.new(:pointer)
            err = ConfErr.new

            open_func = direct ? method(:puavo_conf_open_direct) \
                               : method(:puavo_conf_open)
            if open_func.call(puavoconf_p, err) == -1 then
                raise Puavo::Conf::Error, err[:msg].to_ptr.read_string
            end

            puavoconf = puavoconf_p.read_pointer
            puavoconf_p.free

            @puavoconf = puavoconf
        end

        def get(key)
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            value_p = FFI::MemoryPointer.new(:pointer)
            err = ConfErr.new

            if puavo_conf_get(@puavoconf, key, value_p, err) == -1
                raise Puavo::Conf::Error, err[:msg].to_ptr.read_string
            end

            value = value_p.read_pointer.read_string
            value_p.free

            return value
        end

        def get_all()
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            list = ConfList.new
            err  = ConfErr.new

            if puavo_conf_get_all(@puavoconf, list, err) == -1
                raise Puavo::Conf::Error, err[:msg].to_ptr.read_string
            end

            return [], [] if list[:length] == 0

            keys   = list[:keys].get_array_of_string(0, list[:length]).compact
            values = list[:values].get_array_of_string(0, list[:length]).compact

            puavo_conf_list_free(list)

            return keys, values
        end

        def has_key?(key)
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            value_p = FFI::MemoryPointer.new(:pointer)
            err = ConfErr.new

            if puavo_conf_has_key(@puavoconf, key, value_p, err) == -1
                raise Puavo::Conf::Error, err[:msg].to_ptr.read_string
            end

            value = value_p.read_int
            value_p.free

            return value != 0
        end

        def set(key, value)
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            err = ConfErr.new

            if puavo_conf_set(@puavoconf, key.to_s, value.to_s, err) == -1
                raise Puavo::Conf::Error, err[:msg].to_ptr.read_string
            end
        end

        def clear
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            err = ConfErr.new

            if puavo_conf_clear(@puavoconf, err) == -1
                raise Puavo::Conf::Error, err[:msg].to_ptr.read_string
            end
        end

        def close
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            err = ConfErr.new

            if puavo_conf_close(@puavoconf, err) == -1
                raise Puavo::Conf::Error, err[:msg].to_ptr.read_string
            end
            @puavoconf = nil
        end

        def add(key, value)
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            err = ConfErr.new

            if puavo_conf_add(@puavoconf, key.to_s, value.to_s, err) == -1
                raise Puavo::Conf::Error, err[:msg].to_ptr.read_string
            end
        end

        def overwrite(key, value)
            raise Puavo::Conf::Error, 'Puavodb is not open' unless @puavoconf

            err = ConfErr.new

            if puavo_conf_overwrite(@puavoconf, key.to_s, value.to_s, err) == -1
                raise Puavo::Conf::Error, err[:msg].to_ptr.read_string
            end
        end

    end
end
