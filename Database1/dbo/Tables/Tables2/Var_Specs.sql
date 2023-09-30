CREATE TABLE [dbo].[Var_Specs] (
    [VS_Id]            INT                   IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [AS_Id]            INT                   NULL,
    [Comment_Id]       INT                   NULL,
    [Deviation_From]   INT                   NULL,
    [Effective_Date]   DATETIME              NOT NULL,
    [Esignature_Level] INT                   NULL,
    [Expiration_Date]  DATETIME              NULL,
    [First_Exception]  INT                   NULL,
    [Is_Defined]       INT                   NULL,
    [Is_Deviation]     INT                   NULL,
    [Is_L_Rejectable]  TINYINT               NULL,
    [Is_OverRidable]   INT                   NULL,
    [Is_OverRiden]     INT                   NULL,
    [Is_U_Rejectable]  TINYINT               NULL,
    [L_Control]        [dbo].[Varchar_Value] NULL,
    [L_Entry]          [dbo].[Varchar_Value] NULL,
    [L_Reject]         [dbo].[Varchar_Value] NULL,
    [L_User]           [dbo].[Varchar_Value] NULL,
    [L_Warning]        [dbo].[Varchar_Value] NULL,
    [Prod_Id]          INT                   NOT NULL,
    [T_Control]        [dbo].[Varchar_Value] NULL,
    [Target]           [dbo].[Varchar_Value] NULL,
    [Test_Freq]        INT                   NULL,
    [U_Control]        [dbo].[Varchar_Value] NULL,
    [U_Entry]          [dbo].[Varchar_Value] NULL,
    [U_Reject]         [dbo].[Varchar_Value] NULL,
    [U_User]           [dbo].[Varchar_Value] NULL,
    [U_Warning]        [dbo].[Varchar_Value] NULL,
    [Var_Id]           INT                   NOT NULL,
    CONSTRAINT [Var_Specs_PK_VSId] PRIMARY KEY NONCLUSTERED ([VS_Id] ASC),
    CONSTRAINT [Var_Specs_CC_ExpDate] CHECK ([Expiration_Date] IS NULL OR [Expiration_Date]>=[Effective_Date]),
    CONSTRAINT [Var_Specs_FK_ASId] FOREIGN KEY ([AS_Id]) REFERENCES [dbo].[Active_Specs] ([AS_Id]),
    CONSTRAINT [Vars_Specs_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [Vars_Specs_FK_VarId] FOREIGN KEY ([Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [Var_Specs_By_Var_Prod_Effect] UNIQUE CLUSTERED ([Var_Id] ASC, [Prod_Id] ASC, [Effective_Date] ASC)
);


GO
CREATE NONCLUSTERED INDEX [VarSpecs_IDX_VSIdExpirationDate]
    ON [dbo].[Var_Specs]([VS_Id] ASC, [Expiration_Date] ASC);


GO
CREATE NONCLUSTERED INDEX [VarSpecs_IDX_EffExp]
    ON [dbo].[Var_Specs]([Effective_Date] ASC, [Expiration_Date] ASC);


GO
CREATE NONCLUSTERED INDEX [Var_Specs_By_ASID_ExpDate]
    ON [dbo].[Var_Specs]([AS_Id] ASC, [Expiration_Date] ASC);


GO
Create  TRIGGER dbo.VarSpecs_Reload_InsUpdDel
 	 ON dbo.Var_Specs
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
Update cxs_service set Should_Reload_Timestamp = DateAdd(minute,5,dbo.fnServer_CmnGetDate(getUTCdate())) where Service_Id in (8)
