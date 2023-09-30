/* This sp is called by dbo.spBatch_CheckEventTable parameters need to stay in sync*/
CREATE PROCEDURE dbo.spEM_CreateProdUnit
  @Description nvarchar(50),
  @PL_Id       int,
  @User_Id int,
  @PU_Id       int OUTPUT AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create production line.
  --
  DECLARE @Insert_Id integer,@Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateProdUnit',
                @Description + ','  + Convert(nVarChar(10), @PL_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  INSERT INTO Prod_Units(PU_Desc, PL_Id,Chain_Start_Time,Uses_Start_Time)
 	 VALUES(@Description,@PL_Id,1,1)
  SELECT @PU_Id = PU_Id FROM Prod_Units WHERE PU_Desc = @Description And PL_Id = @PL_Id
  IF @PU_Id IS NULL
 	 BEGIN
 	      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
 	      RETURN(1)
 	 END
 	 Declare @OV VarChar(4000)
 	 Select @OV = OverView_Positions from prod_Lines where PL_Id = @PL_Id
 	 Declare @Start int
 	 Select @Start = 0
 	 Select @Start = CharIndex('PEP',@OV,1)
 	 If @Start > 0
 	   Begin
 	  	  	 Select  @OV = substring(@OV,1,@Start + 3) + 'ah'+ Char(1) + Convert(nVarChar(10),@PU_Id) + Char(1) + '100' + Char(1) + '100' + Char(1) +  substring(@OV,@Start + 4,len(@OV) -(@Start + 2))
 	  	  	 Update prod_Lines set OverView_Positions = @OV
 	  	  	  Where PL_Id = @PL_Id
 	   End
 	 Select @Start = 0
 	 Select @Start = CharIndex('ICON',@OV,1)
 	 If @Start > 0
 	   Begin
 	  	  	 Select  @OV = substring(@OV,1,@Start + 4) + 'ah'+ Char(1) + Convert(nVarChar(10),@PU_Id) + Char(1) + '100' + Char(1) + '100' + Char(1) +  substring(@OV,@Start + 5,len(@OV) -(@Start + 3))
 	  	  	 Update prod_Lines set OverView_Positions = @OV
 	  	  	  	  Where PL_Id = @PL_Id
 	   End
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@PU_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
