CREATE PROCEDURE dbo.spEM_PutProductXRef
  @Prod_Id        int,
  @PU_Id          int,
  @Prod_Code_XRef nvarchar(255),
  @User_Id       int
 AS
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutProductXRef',
                Convert(nVarChar(10),@Prod_Id) + ','  + 
 	  	 Convert(nVarChar(10),@PU_Id) + ','  + 
 	  	 @Prod_Code_XRef + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  IF @Prod_Code_XRef IS NULL
    DELETE FROM Prod_XRef WHERE (Prod_Id = @Prod_Id) AND
      (((@PU_Id IS NOT NULL) AND (PU_Id = @PU_Id)) OR
       ((@PU_Id IS NULL) AND (PU_Id IS NULL)))
  ELSE
    BEGIN
      DECLARE @Dummy int
      SELECT @Dummy = Prod_Id FROM Prod_XRef
        WHERE (Prod_Id = @Prod_Id) AND
          (((@PU_Id IS NOT NULL) AND (PU_Id = @PU_Id)) OR
           ((@PU_Id IS NULL) AND (PU_Id IS NULL)))
      IF @Dummy IS NULL
   	 INSERT Prod_XRef(Prod_Id, PU_Id, Prod_Code_XRef)
          VALUES(@Prod_Id, @PU_Id, @Prod_Code_XRef)
      ELSE
        UPDATE Prod_XRef
          SET Prod_Code_XRef = @Prod_Code_XRef
          WHERE (Prod_Id = @Prod_Id) AND
            (((@PU_Id IS NOT NULL) AND (PU_Id = @PU_Id)) OR
             ((@PU_Id IS NULL) AND (PU_Id IS NULL)))
    END
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
