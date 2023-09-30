CREATE PROCEDURE dbo.spEM_PutTransCharLinks
  @Trans_Id int,
  @FromChar_Id int,
  @ToChar_Id 	 int,
  @User_Id    	 int
  AS
  --
  -- Declare local variables.
  --
  DECLARE @Insert_Id 	  	 Integer, 
  	        @Id 	  	 Integer,
 	        @TransOrder 	 Integer,
 	        @OldOrder 	  	 Integer,
 	        @CharId 	  	 Integer,
 	        @SpecId 	  	 Integer,
 	        @PropId 	  	 Integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutTransCharLinks',
                Convert(nVarChar(10),@Trans_Id) + ','  + 
                Convert(nVarChar(10),@FromChar_Id) + ','  + 
                Convert(nVarChar(10),@ToChar_Id) + ','  + 
                Convert(nVarChar(10),@User_id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  SELECT @Id = Trans_Id From Trans_Char_Links
 	 WHERE Trans_Id = @Trans_Id and From_Char_Id = @FromChar_Id
  --
  SELECT @TransOrder = Count(*) From Trans_Char_Links
   WHERE Trans_Id = @Trans_Id
  IF @Id IS NULL 
     BEGIN
 	 Insert Into Trans_Char_Links(Trans_Id, From_Char_Id,To_Char_Id,TransOrder)
 	 Values(@Trans_Id,@FromChar_Id,@ToChar_Id,@TransOrder+1)
     END
  ELSE
     BEGIN
 	 Select @OldOrder = TransOrder  From Trans_Char_Links
 	      Where Trans_Id = @Trans_Id and From_Char_Id = @FromChar_Id
 	 Delete  From Trans_Char_Links
 	   Where Trans_Id = @Trans_Id and From_Char_Id = @FromChar_Id
 	 Update  Trans_Char_Links Set TransOrder = TransOrder -1
 	   Where Trans_Id = @Trans_Id and TransOrder > @OldOrder
 	 Insert Into Trans_Char_Links(Trans_Id, From_Char_Id,To_Char_Id,TransOrder)
 	    Values(@Trans_Id,@FromChar_Id,@ToChar_Id,@TransOrder)
     END
Create Table #CharIds(Char_Id Int)
Create Table #CharId1(Char_Id Int)
Create Table #CharId2(Char_Id Int)
Insert Into #CharIds(Char_Id) Values(@FromChar_Id)
Insert Into #CharId1(Char_Id) Values(@FromChar_Id)
Loop:
  Delete From #CharId2
  Insert InTo #CharId2 Select Char_Id From Characteristics where Derived_From_Parent in (select Char_Id From  #CharId1)
  If @@RowCount > 0 
      Begin
         Insert InTo #CharIds Select Char_Id From #CharId2
         Delete From #CharId1
         Insert Into #CharId1 select * From #CharId2
         Goto Loop
      End
     Delete From Trans_Properties Where Trans_Id = @Trans_Id and Char_Id in (select Char_Id From #CharIds)
  --
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
