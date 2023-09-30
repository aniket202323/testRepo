CREATE PROCEDURE dbo.spEM_DropUserGroup
  @Group_Id int,
  @User_Id   int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   50105 = drop of admin
  -- Delete the product group data.
  --
  --
  -- Change all the objects belonging to this group and give them
  -- to the administrative group.
  --
   DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropUserGroup',
                 convert(nVarChar(10),@Group_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
   IF @Group_Id = 1
 	 BEGIN
 	       UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 50105
 	  	  WHERE Audit_Trail_Id = @Insert_Id
 	       RETURN (50105)
 	 END
  BEGIN TRANSACTION
  UPDATE Prod_Lines 	  	 SET Group_Id = Null WHERE Group_Id = @Group_Id
  UPDATE Prod_Units 	  	 SET Group_Id = Null WHERE Group_Id = @Group_Id
  UPDATE Sheets 	  	  	 SET Group_Id = Null WHERE Group_Id = @Group_Id
  UPDATE Variables_Base 	  	 SET Group_Id = Null WHERE Group_Id = @Group_Id
  UPDATE COA 	  	  	 SET Group_Id = Null WHERE Group_Id = @Group_Id
  UPDATE Characteristics 	 SET Group_Id = Null WHERE Group_Id = @Group_Id
  UPDATE Product_Family 	  	 SET Group_Id = Null WHERE Group_Id = @Group_Id
  UPDATE PU_Groups  	  	 SET Group_Id = Null WHERE Group_Id = @Group_Id
  UPDATE Sheets  	  	 SET Group_Id = Null WHERE Group_Id = @Group_Id
  UPDATE Specifications 	  	 SET Group_Id = Null WHERE Group_Id = @Group_Id
  --
  -- Delete the user group and its members.
  --
  DELETE FROM User_Security WHERE Group_Id = @Group_Id
  DELETE FROM Security_Groups WHERE Group_Id = @Group_Id
  --
  -- Commit the transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
