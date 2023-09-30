Create Procedure dbo.spEM_AppTransCharLinks
  @Trans_Id 	 Int,
  @User_Id 	 Int
  AS
  --
  -- Insert new record into the active specifications table and determine the
  -- identity of the newly inserted record.
  --
  DECLARE @Insert_Id 	  	 Int ,
 	       @RetCode 	  	  	 Int,
 	       @From_Char_Id 	  	 Int,
 	       @To_Char_Id 	  	 Int
DECLARE @Now 	  	  	 DateTime,
 	  	 @LEntry 	  	  	 nVarChar(25),
 	  	 @LReject 	  	 nVarChar(25),
 	  	 @LWarning 	  	 nVarChar(25),
 	  	 @LUser 	  	  	 nVarChar(25),
 	  	 @Target 	  	  	 nVarChar(25),
 	  	 @UUser 	  	  	 nVarChar(25),
 	  	 @UWarning 	  	 nVarChar(25),
 	  	 @UReject 	  	 nVarChar(25),
 	  	 @UEntry  	  	 nVarChar(25),
 	  	 @TestFreq  	  	 INT,
 	  	 @Sig 	  	  	 INT,
 	  	 @LControl 	  	 nVarChar(25),
 	  	 @TControl 	  	 nVarChar(25),
 	  	 @UControl 	  	 nVarChar(25),
 	  	 @ASId 	  	  	 INT,
 	  	 @IsDefined 	  	 INT
SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_AppTransCharLinks',
 	  Convert(nVarChar(10),@Trans_Id) + ','  + 
 	  Convert(nVarChar(10), @User_Id),
              dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
 Declare Trans_Cursor Cursor
    For Select   From_Char_Id,To_Char_Id From Trans_Char_Links Where  Trans_Id  = @Trans_Id Order By TransOrder
    For Read Only
    Open Trans_Cursor
Next_Trans:
    Fetch Next From Trans_Cursor InTo   @From_Char_Id, @To_Char_Id
    If @@Fetch_Status = 0 
        Begin
 	 Update Characteristics set  Derived_From_Parent =  @To_Char_Id Where Char_Id = @From_Char_Id
 	 
 	 IF  @To_Char_Id IS Null
 	 BEGIN
 	  	 DECLARE asCursor CURSOR FOR 
 	  	  	 SELECT AS_Id,L_Entry,L_Reject,L_Warning,L_User,Target,
 	  	  	  	 U_Entry,U_Reject,U_User,U_Warning,
 	  	  	  	 Test_Freq,Esignature_Level,L_Control,T_Control,U_Control
 	  	  	 FROM Active_Specs
 	  	  	 WHERE (Expiration_Date is Null or Expiration_Date > @Now) And Char_Id = @From_Char_Id
 	  	  	 FOR Update
 	  	 Open asCursor
Next_As:
 	  	 Fetch Next From asCursor Into 	 @ASId,@LEntry,@LReject,@LWarning,@LUser,@Target,
 	  	  	  	  	  	  	  	  	  	 @UEntry,@UReject,@UUser,@UWarning,
 	  	  	  	  	  	  	  	  	  	 @TestFreq,@Sig,@LControl,@TControl,@UControl
 	  	 If @@Fetch_Status = 0 
 	  	 BEGIN
 	  	  	 SELECT @IsDefined = 0
 	  	  	 IF @LEntry is not null 	  	 SELECT @IsDefined = @IsDefined + 1
 	  	  	 IF @LReject is not null 	  	 SELECT @IsDefined = @IsDefined + 2
 	  	  	 IF @LWarning is not null 	 SELECT @IsDefined = @IsDefined + 4
 	  	  	 IF @LUser is not null 	  	 SELECT @IsDefined = @IsDefined + 8
 	  	  	 IF @Target is not null 	  	 SELECT @IsDefined = @IsDefined + 16
 	  	  	 IF @UUser is not null 	  	 SELECT @IsDefined = @IsDefined + 32
 	  	  	 IF @UWarning is not null 	 SELECT @IsDefined = @IsDefined + 64
 	  	  	 IF @UReject is not null 	  	 SELECT @IsDefined = @IsDefined + 128
 	  	  	 IF @UEntry is not null 	  	 SELECT @IsDefined = @IsDefined + 256
 	  	  	 IF @TestFreq is not null 	 SELECT @IsDefined = @IsDefined + 512
 	  	  	 IF @Sig is not null 	  	  	 SELECT @IsDefined = @IsDefined + 1024
 	  	  	 IF @LControl is not null 	 SELECT @IsDefined = @IsDefined + 8192
 	  	  	 IF @TControl is not null 	 SELECT @IsDefined = @IsDefined + 16384
 	  	  	 IF @UControl is not null 	 SELECT @IsDefined = @IsDefined + 32768
 	  	  	 UPDATE Active_Specs Set Is_Defined = @IsDefined WHERE CURRENT OF asCursor
 	  	  	 GOTO Next_As
 	  	 END
 	  	 CLOSE asCursor
 	  	 DEALLOCATE asCursor
 	 END
 	 ELSE
 	 BEGIN
 	  	 UPDATE Active_Specs set Is_Defined = Null
 	  	  	 WHERE (Expiration_Date is Null or Expiration_Date > @Now) And Char_Id = @From_Char_Id
 	 END
 	 GoTo Next_Trans
        End
  Close Trans_Cursor
  Deallocate Trans_Cursor
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
Return (0)
