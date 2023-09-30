CREATE TABLE [dbo].[Active_Specs] (
    [AS_Id]            INT                   IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Char_Id]          INT                   NOT NULL,
    [Comment_Id]       INT                   NULL,
    [Defined_By]       INT                   NULL,
    [Deviation_From]   INT                   NULL,
    [Effective_Date]   DATETIME              NOT NULL,
    [Esignature_Level] INT                   NULL,
    [Expiration_Date]  DATETIME              NULL,
    [Is_Defined]       INT                   NULL,
    [Is_Deviation]     INT                   NULL,
    [Is_L_Rejectable]  TINYINT               NULL,
    [Is_OverRidable]   INT                   NULL,
    [Is_U_Rejectable]  TINYINT               NULL,
    [L_Control]        [dbo].[Varchar_Value] NULL,
    [L_Entry]          [dbo].[Varchar_Value] NULL,
    [L_Reject]         [dbo].[Varchar_Value] NULL,
    [L_User]           [dbo].[Varchar_Value] NULL,
    [L_Warning]        [dbo].[Varchar_Value] NULL,
    [Spec_Id]          INT                   NOT NULL,
    [T_Control]        [dbo].[Varchar_Value] NULL,
    [Target]           [dbo].[Varchar_Value] NULL,
    [Test_Freq]        INT                   NULL,
    [U_Control]        [dbo].[Varchar_Value] NULL,
    [U_Entry]          [dbo].[Varchar_Value] NULL,
    [U_Reject]         [dbo].[Varchar_Value] NULL,
    [U_User]           [dbo].[Varchar_Value] NULL,
    [U_Warning]        [dbo].[Varchar_Value] NULL,
    CONSTRAINT [Active_Specs_PK_ASId] PRIMARY KEY CLUSTERED ([AS_Id] ASC),
    CONSTRAINT [Active_Specs_CC_Chk_EffExp] CHECK ([Expiration_Date] IS NULL OR [Expiration_Date]>=[Effective_Date]),
    CONSTRAINT [Active_Specs_FK_CharId] FOREIGN KEY ([Char_Id]) REFERENCES [dbo].[Characteristics] ([Char_Id]),
    CONSTRAINT [Active_Specs_FK_SpecId] FOREIGN KEY ([Spec_Id]) REFERENCES [dbo].[Specifications] ([Spec_Id]),
    CONSTRAINT [Active_Specs_UC_SpecIdCharIdED] UNIQUE NONCLUSTERED ([Spec_Id] ASC, [Char_Id] ASC, [Effective_Date] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ActiveSpecs_IDX_ASIdExpirationDate]
    ON [dbo].[Active_Specs]([AS_Id] ASC, [Expiration_Date] ASC);


GO
CREATE NONCLUSTERED INDEX [Active_Specs_IDX_CharId]
    ON [dbo].[Active_Specs]([Char_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Active_Specs_IDX2_SpecId]
    ON [dbo].[Active_Specs]([Spec_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Active_Specs_IDX_CharSpecEff]
    ON [dbo].[Active_Specs]([Spec_Id] ASC, [Char_Id] ASC, [Effective_Date] ASC);


GO
Create  TRIGGER dbo.ActiveSpecs_Reload_InsUpdDel
 	 ON dbo.Active_Specs
 	 FOR INSERT, UPDATE, DELETE
 	 AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 	 Declare @ShouldReload Int
 	 Select @ShouldReload = sp.Value 
 	  	 From Parameters p
 	  	 Join Site_Parameters sp on p.Parm_Id = sp.Parm_Id
 	  	 Where Parm_Name = 'Perform automatic service reloads'
 	 If @ShouldReload is null or @ShouldReload = 0 
 	  	 Return
/*
2  -Database Mgr
4  -Event Mgr
5  -Reader
6  -Writer
7  -Summary Mgr
8  -Stubber
9  -Message Bus
14 -Gateway
16 -Email Engine
17 -Alarm Manager
18 -FTP Engine
19 -Calculation Manager
20 -Print Server
22 -Schedule Mgr
*/
Update cxs_service set Should_Reload_Timestamp = DateAdd(minute,5,dbo.fnServer_CmnGetDate(getUTCdate())) where Service_Id in (17,22)

GO
CREATE TRIGGER [dbo].[Active_Specs_TableFieldValue_Del]
 ON  [dbo].[Active_Specs]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.AS_Id
 WHERE tfv.TableId = 39
