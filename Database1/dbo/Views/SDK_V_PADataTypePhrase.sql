CREATE view SDK_V_PADataTypePhrase
as
select
Phrase.Phrase_Id as Id,
Data_Type.Data_Type_Desc as DataType,
Phrase.Phrase_Value as DataTypePhrase,
Phrase.Phrase_Order as DataTypePhraseOrder,
Phrase.Comment_Required as CommentRequired,
Phrase.Active as IsActive,
Phrase.Data_Type_Id as DataTypeId
FROM Phrase
 join data_type on phrase.data_type_id = data_type.data_type_id
