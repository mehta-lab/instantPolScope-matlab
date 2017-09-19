function structure=ObjPropsToStruct(object)
% Generate a structure with same fields and values as the properties of the
% object. Effectively cast the object to structure.

props=fieldnames(object);
for idx=1:length(props)
    structure.(props{idx})=object.(props{idx});
end
    
end