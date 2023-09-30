CREATE PROCEDURE dbo.spEM_IEImportDataTypes
@Data_Type_Desc  	 nVarChar(100),
@Phrase_Value 	  	 nVarChar(100),
@UserId 	  	  	  	  	 Int 	 
AS
Declare @Description  	 nVarChar(100),
 	  	 @Phrase_Order  	 int,
 	  	 @Data_Type_Id 	 Int,
 	     @Phrase_Id 	  	 int
 	  	 
/* Initialization */
Select  	 @Data_Type_Id = Null,
 	 @Phrase_Id = Null,
 	 @Phrase_Order = Null
/******************************************************************************************/
/* Create/Update Data Types 	  	    	  	  	  	 */
/******************************************************************************************/
Select @Description = RTrim(LTrim(@Data_Type_Desc))
If @Description = '' or @Description IS NULL
 BEGIN
   Select  'Failed - data type field required'
   Return(-100)
 END
If LEN(@Description) > 50
 BEGIN
   Select  'Failed - data type to long (Max 50)'
   Return(-100)
 END
If LTrim(RTrim(@Phrase_Value)) = ''  or @Phrase_Value IS NULL
 BEGIN
   Select  'Failed - phrase field required'
   Return(-100)
 END
If LEN(LTrim(RTrim(@Phrase_Value))) > 25
 BEGIN
   Select  'Failed - phrase to long (Max 25)'
   Return(-100)
 END
Select @Data_Type_Id = Data_Type_Id
From Data_Type
Where Data_Type_Desc = @Description
If @Data_Type_Id Is Null
  Begin
 	 Execute spEM_CreateDataType @Description,@UserId,@Data_Type_Id Output
 	 If @Data_Type_Id is Null or @Phrase_Id = 0
 	  Begin
 	   Select 'Failed - error creating data type'
 	   Return (-100)
 	  End
  End
/******************************************************************************************/
/* Create/Update phrases 	   	   	  	  	  	 */
/******************************************************************************************/
If @Data_Type_Id Is Not Null
Begin
     Select @Phrase_Value = RTrim(LTrim(@Phrase_Value))
     Select @Phrase_Id = Phrase_Id
     From Phrase
     Where Phrase_Value = @Phrase_Value And Data_Type_Id = @Data_Type_Id
     If @Phrase_Id Is Null
     Begin
          /* Get next Phrase_Order */
          Select @Phrase_Order = Max(Phrase_Order) + 1
          From Phrase
          Where Data_Type_Id = @Data_Type_Id
          If @Phrase_Order Is Null
               Select @Phrase_Order = 1
 	  	   Execute spEM_CreatePhrase @Data_Type_Id,@Phrase_Value,@Phrase_Order,@UserId,@Phrase_Id OUTPUT
 	  	  If @Phrase_Id is Null or @Phrase_Id = 0
 	  	  	 Begin
 	  	  	   Select 'Failed - Error Creating Phrase'
 	  	  	   Return (-100)
 	  	  	 End
     End
End
