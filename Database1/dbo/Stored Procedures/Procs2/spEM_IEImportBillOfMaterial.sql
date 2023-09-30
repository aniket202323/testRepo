CREATE PROCEDURE dbo.spEM_IEImportBillOfMaterial
 	 @BOM_Desc  	  	  	  	 nvarchar(255),
 	 @Comment1  	  	  	  	 nvarchar(255),
 	 @BOM_Family_Desc  	 nvarchar(255),
 	 @Comment2 	  	  	  	  	 nvarchar(255),
 	 @User_Id  	  	  	  	  	 int
AS
Declare 
 	 @CommentId int,
 	 @CS int,
 	 @BOM_Family_Id int,
 	 @BOM_Id int
Select @BOM_Family_Desc = LTrim(RTrim(@BOM_Family_Desc))
Select @BOM_Desc = LTrim(RTrim(@BOM_Desc))
Select @Comment1 = LTrim(RTrim(@Comment1))
Select @Comment2 = LTrim(RTrim(@Comment2))
Select @BOM_Id = Null
Select @BOM_Family_Id = Null
Select @BOM_Id = BOM_Id from Bill_Of_Material 
 	 where BOM_Desc = @BOM_Desc
If @BOM_Id IS NOT NULL
    BEGIN
      Select 'Failed - Bill Of Material already exists'
      RETURN (-100)
    END
If @BOM_Family_Desc <> '' and @BOM_Family_Desc IS NOT NULL
  BEGIN
    -- Add the product family if it doesn't exist
    select @CS=CS_Id from Comment_Source where CS_Desc='AutoLog'
    Select @BOM_Family_Id = NULL
    Select @BOM_Family_Id = BOM_Family_Id 
      From Bill_Of_Material_Family
      Where BOM_Family_Desc = @BOM_Family_Desc
    If @BOM_Family_Id IS NULL 
      BEGIN
        exec spEM_BOMSaveFamily null,null,@BOM_Family_Desc,@BOM_Family_Id OUTPUT
        If @BOM_Family_Id IS NULL
          BEGIN
       	  	 Select 'Failed - Could not create Bill Of Material family'
       	  	 RETURN (-100)
          END
      END
   End
   Execute spEM_BOMSave @BOM_Family_Id,1,null,null,@BOM_Desc,@BOM_Id OUTPUT
   If @BOM_Id IS NULL
    BEGIN
      Select 'Failed - Could not create Bill Of Material'
      RETURN (-100)
    END
 	 if @Comment1 <> '' and @Comment1 IS NOT NULL 
 	 begin
 	  	 exec spEM_CreateComment @BOM_Id,'fm',@User_Id,@CS,@CommentId out
 	  	 Update Comments set Comment = @Comment1 Where Comment_Id = @CommentId
 	 end
 	 If @Comment2 <> '' and @Comment2 IS NOT NULL 
 	 Begin
 	  	 SELECT @CommentId = Null
        exec spEM_CreateComment @BOM_Family_Id,'fk',@User_Id,@CS,@CommentId out
 	  	 Update Comments set Comment = @Comment2 Where Comment_Id = @CommentId
 	 End
RETURN(0)
