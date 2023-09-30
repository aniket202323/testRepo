CREATE PROCEDURE dbo.spEM_IEImportSpecVariables
@Prop_Desc  	  	 nvarchar(50),
@Spec_Desc  	  	 nvarchar(50),
@Data_Type_Desc  	 nvarchar(50),
@Spec_Precision  	 nvarchar(50),
@Eng_Units 	  	 nvarchar(50),
@Tag 	  	  	 nvarchar(50),
@Extended_Info  	  	 nvarchar(255),
@External_Link 	  	 nvarchar(255),
@Comment  	  	 nvarchar(1000),
@User_Id  	  	 int
AS
Declare 	 @Data_Type_Id 	 int,
 	  	 @Prop_Id  	 int,
 	  	 @Spec_Id 	 int,
 	  	 @Spec_Order 	 int,
 	  	 @Comment_Id 	 Int,
 	  	 @iPrecision 	 int
/* Initialization */
Select 	 @Data_Type_Id 	 = Null,
 	  	 @Prop_Id 	  	 = Null,
 	  	 @Spec_Id 	  	 = Null,
 	  	 @Prop_Id  	  	 = Null, 	 
 	  	 @Spec_Id 	  	 = Null
/* Clean and verify arguments */
Select  	 @Prop_Desc 	  	 = ltrim(rtrim(@Prop_Desc)),
 	  	 @Spec_Desc 	  	 = ltrim(rtrim(@Spec_Desc)),
 	  	 @Data_Type_Desc 	 = ltrim(rtrim(@Data_Type_Desc)),
 	  	 @Eng_Units 	  	 = ltrim(rtrim(@Eng_Units)),
 	  	 @Tag 	  	  	 = ltrim(rtrim(@Tag)),
 	  	 @Extended_Info 	 = ltrim(rtrim(@Extended_Info)),
 	  	 @External_Link 	  	 = ltrim(rtrim(@External_Link))
Select @Comment = LTrim(RTrim(@Comment))
IF @Comment = '' Select @Comment = Null
If @Data_Type_Desc Is Null Or @Data_Type_Desc = ''
     Select @Data_Type_Desc = 'Float'
If @Data_Type_Desc <> 'Float'
     Select @iPrecision = 0
Else If @Spec_Precision Is Null
      Select @iPrecision = 0
     Else If isnumeric(@Spec_Precision) <> 0
 	        Select @iPrecision = convert(Int,@Spec_Precision)
 	       Else
 	  	     Select @iPrecision = 0
/* Get configuration ids */
Select @Data_Type_Id = Data_Type_Id
From Data_Type
Where Data_Type_Desc = @Data_Type_Desc
If @Data_Type_Id Is Null
  Begin
 	 Select 'Failed - incorrect data type'
     Return (-100)
  End
/*  Create properties and specifications */
Select @Prop_Id = Prop_Id 
From Product_Properties
Where Prop_Desc = @Prop_Desc
If @Prop_Id Is Null
 Begin
 	 Execute spEM_CreateProp @Prop_Desc,1,@User_Id,@Prop_Id OUTPUT
    If @Prop_Id Is Null 
 	   Begin
 	  	 Select 'Failed - could not create product property'
      	 Return (-100)
 	   End
 End
Select @Spec_Id = Spec_Id 
From Specifications
Where Spec_Desc = @Spec_Desc and Prop_Id = @Prop_Id
If @Spec_Id Is Null
  Begin
 	 Execute spEM_CreateSpec @Spec_Desc,@Prop_Id,@Data_Type_Id,@iPrecision, @User_Id,@Spec_Id OUTPUT, @Spec_Order OUTPUT
 	 If @Spec_Id is null
 	   Begin
 	  	 Select 'Failed - could not create specification variable'
      	 Return (-100)
 	   End
  End
If @Comment IS NOT NULL 
BEGIN
    -- If the Specvariable already has a comment, update it. 
   Select @Comment_Id  = Comment_Id  from Specifications Where Spec_Id = @Spec_Id
   If @Comment_Id IS NULL 
    BEGIN
 	  	  	 Execute spEM_CreateComment @Spec_Id,'as',@User_Id,3,@Comment_Id OUTPUT
    END
    IF @Comment_Id is not Null
    BEGIN
        Update Comments Set Comment = @Comment Where Comment_Id = @Comment_Id
        Update Comments Set Comment_Text = @Comment Where Comment_Id = @Comment_Id
    END
    ELSE
    BEGIN
        Select 'Failed - Could not create Comment for product'
        RETURN (-100)
    END
 END
Execute spEM_PutSpecData  @Spec_Id,@Data_Type_Id,@Spec_Precision,@Tag,@Eng_Units,@User_Id
Execute spEM_PutExtLink @Spec_Id,'as', @External_Link,@Extended_Info,0, @User_Id
Return (0)
