Create Procedure dbo.spAL_LookupPhrases
  @DataType_Id int
As
Select Phrase_Value from Phrase where Data_Type_Id = @DataType_Id
