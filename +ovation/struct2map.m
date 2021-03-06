function m = struct2map(s, options)
% Create a java.util.Map from a Matlab struct
%
%  m = struct2map(s)
%
%    s: Matlab struct
%
% Empty values ([]) are converted to the string "<empty>". Nested
% structs are converted to a flat map by substituting "." => "__". For
% example, field1.field2 becomes the key "field1__field2". Function
% handles are converted to a string using func2str. Cell string arrays
% are converted via cell2mat. Other cell arrays are unsupported.
%
% Example Usage
% -------------
% >> s.key1 = 10;
% >> s.key2 = 'abc';
% >> s.key3 = [1,2,3]
% 
% s = 
% 
%     key1: 10
%     key2: 'abc'
%     key3: [1 2 3]
% 
% >> m = struct2map(s)
%  
% m =
%  
% {key3=[D@3ff1b8db, key2=abc, key1=10.0}
%  
% >> map2struct(m)
% 
% ans = 
% 
%     key3: [3x1 double]
%     key2: 'abc'
%     key1: 10
	
% Copyright (c) 2012 Physion Consulting LLC

    opts.strict = false;
    if(nargin > 1)
        opts = ovation.mergeStruct(opts, options);
    end

    m = struct2map_(s, [], '', opts);
    
end

function m = struct2map_(s, m, prefix, opts)
    
    import ovation.*;
    import java.util.HashMap;
    keys = fieldnames(s);

    if(isempty(m))
        m = java.util.HashMap(length(keys));
    end
    
    for i=1:length(keys)
        value = s.(keys{i});
        if(isstruct(value))
            for j = 1:length(value)
                v = value(j);
                if(length(value) > 1)
                    elementSuffix = ['(' num2str(j) ')'];
                else
                    elementSuffix = '';
                end
                
                if(~isempty(prefix))
                    newPrefix = [prefix '.' keys{i} elementSuffix];
                else
                    newPrefix = [keys{i} elementSuffix];
                end
                
                m = struct2map_(v, m, newPrefix);
            end
        elseif isobject(value) && length(value) == 1 
            % && sum(strcmp(methods(value),'subsref')) % call if object has
            % a subsref method
            v = value;            
            if(~isempty(prefix))
                newPrefix = [prefix '.' keys{i}];
            else
                newPrefix = [keys{i}];
            end
            
            m = struct2map_(v, m, newPrefix);
        else
            if(ischar(value))
                value = java.lang.String(value);
            elseif(isempty(value))
                value = '<empty>';
            elseif(isa(value, 'function_handle'))
                value = func2str(value);
            elseif(iscellstr(value))
                value = cell2mat(value);
            elseif(iscell(value))
                id = 'ovation:struct2map:unsupported_value';
                msg = ['struct2map does not support cell-array values (key ' keys{i} ')'];
                if(opts.strict)
                    error(id, msg);
                else
                    warning(id, msg);
                end
                continue;
            end
            
            if(isempty(prefix))
                key = keys{i};
            else
                key = [prefix '.' keys{i}];
            end
            
            m.put(java.lang.String(key), value);
        end
        
    end
end
