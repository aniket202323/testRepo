CREATE PROCEDURE dbo.spServer_AMgrGetPhrases
 AS
select  Data_Type_Id, Phrase_Order, Phrase_Value from phrase where (Active is not null and Active <> 0) order by Data_Type_Id, Phrase_Order asc
