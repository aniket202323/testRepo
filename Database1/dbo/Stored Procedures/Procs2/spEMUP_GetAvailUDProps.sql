CREATE Procedure dbo.spEMUP_GetAvailUDProps
@KeyId int,
@Table_Id int,
@User_Id int,
@Table_Field_Desc nvarchar(50) = NULL,
@ED_Field_Type_Id int = NULL,
@Table_Field_Id int = NULL
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMUP_GetAvailUDProps',
             Convert(nVarChar(10),@KeyId) + ','  + 
             Convert(nVarChar(10),@Table_Id) + ','  + 
             Convert(nVarChar(10),@User_Id) + ','  + 
             @Table_Field_Desc + ','  + 
             Convert(nVarChar(10),@ED_Field_Type_Id) + ','  + 
             Convert(nVarChar(10),@Table_Field_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @Table_Field_Id is NULL
  Begin
    If @Table_Field_Desc is NULL and @ED_Field_Type_Id is NULL
      Begin
        Select Table_Field_Id, Table_Field_Desc,ED_Field_Type_Id
          From Table_Fields
 	  	   WHERE TableId = @Table_Id
          Order By Table_Field_Desc ASC
         Select ED_Field_Type_Id, Field_Type_Desc 
 	  	  	  	  	 From ED_FieldTypes 
 	  	  	  	  	 WHERE User_Defined_Property = 1
 	  	  	  	  	 Order By Field_Type_Desc ASC
      End
    Else
      Begin
        Select @Table_Field_Id = Table_Field_Id From Table_Fields Where Table_Field_Desc = ltrim(rtrim(@Table_Field_Desc)) and TableId = @Table_Id
        If @Table_Field_Id is NULL
          Begin
            Select 0 as [Count]
            Insert Into Table_Fields (Table_Field_Desc, ED_Field_Type_Id,TableId) Values (@Table_Field_Desc, @ED_Field_Type_Id,@Table_Id)
            Select @Table_Field_Id = Scope_Identity()
            Insert Into Table_Fields_Values (KeyId, TableId, Table_Field_Id, Value) Values (@KeyId, @Table_Id, @Table_Field_Id, NULL)
          End
        Else
          Begin
            If (Select Count(*) From Table_Fields_Values Where KeyId = @KeyId and TableId = @Table_Id and Table_Field_Id = @Table_Field_Id) = 0
              Begin
                Select 0 as [Count]
                Insert Into Table_Fields_Values (KeyId, TableId, Table_Field_Id, Value) Values (@KeyId, @Table_Id, @Table_Field_Id, NULL)
              End
            Else
              Begin
                Select Count(*) as [Count] From Table_Fields Where Table_Field_Desc = ltrim(rtrim(@Table_Field_Desc)) and TableId = @Table_Id
              End
          End
      End
  End
Else If @Table_Field_Id is NOT NULL
  Begin
    If (Select Count(*) 
          From Table_Fields_Values 
          Where KeyId = @KeyId and TableId = @Table_Id and Table_Field_Id = @Table_Field_Id) > 0
      Begin
        If (Select Count(*) 
              From Table_Fields_Values 
              Where KeyId = @KeyId and TableId = @Table_Id and Table_Field_Id = @Table_Field_Id and Value is NOT NULL) = 0
          Begin
            Select Count(*) as [Count], Msg = 0
              From Table_Fields_Values 
              Where Table_Field_Id = @Table_Field_Id and (KeyId <> @KeyId or TableId <> @Table_Id)
            Delete From Table_Fields_Values Where KeyId = @KeyId and TableId = @Table_Id and Table_Field_Id = @Table_Field_Id
          End
        Else
          Begin
            Select Count(*) as [Count], Msg = 1 
              From Table_Fields_Values
              Where KeyId = @KeyId and TableId = @Table_Id and Table_Field_Id = @Table_Field_Id and Value is NOT NULL
          End
      End
    Else
      Begin
        If (Select Count(*) 
              From Table_Fields_Values 
              Where Table_Field_Id = @Table_Field_Id) = 0
          Begin
            Select 0 as [Count], Msg = 2
            Delete From Table_Fields Where Table_Field_Id = @Table_Field_Id
          End
        Else
          Begin
            Select Count(*) as [Count], Msg = 3
              From Table_Fields_Values 
              Where Table_Field_Id = @Table_Field_Id
          End
      End
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
