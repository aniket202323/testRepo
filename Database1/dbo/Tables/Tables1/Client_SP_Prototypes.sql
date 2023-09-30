CREATE TABLE [dbo].[Client_SP_Prototypes] (
    [Client_SP_Id]       INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Command_Text]       VARCHAR (6000) NOT NULL,
    [CursorType_Id]      TINYINT        CONSTRAINT [CliSpProto_DF_CurTypeId] DEFAULT ((1)) NOT NULL,
    [DeadlockCount]      TINYINT        CONSTRAINT [CliSpProto_DF_DeadLockCnt] DEFAULT ((0)) NOT NULL,
    [ExecCount]          INT            CONSTRAINT [CliSpProto_DF_ExecCnt] DEFAULT ((0)) NOT NULL,
    [ExecMaxMS]          INT            CONSTRAINT [CliSpProto_DF_ExecMaxMS] DEFAULT ((0)) NOT NULL,
    [ExecMinMS]          INT            CONSTRAINT [CliSpProto_DF_ExecMinMS] DEFAULT ((0)) NOT NULL,
    [ExecTotalMinutes]   REAL           CONSTRAINT [CliSpProto_DF_ExecTotMins] DEFAULT ((0)) NOT NULL,
    [Hostname]           VARCHAR (25)   NULL,
    [Input]              INT            CONSTRAINT [CliSpProto_DF_Input] DEFAULT ((0)) NOT NULL,
    [Input_Output]       INT            CONSTRAINT [CliSpProto_DF_InputOutput] DEFAULT ((0)) NOT NULL,
    [Is_Client_Callable] BIT            CONSTRAINT [ClientspPrototypes_DF_IsClientCallable] DEFAULT ((1)) NULL,
    [LockType_Id]        TINYINT        CONSTRAINT [CliSpProto_DF_LockTypeId] DEFAULT ((1)) NOT NULL,
    [MaxRetries]         TINYINT        CONSTRAINT [CliSpProto_DF_MaxRetries] DEFAULT ((0)) NOT NULL,
    [Output]             INT            CONSTRAINT [CliSpProto_DF_Output] DEFAULT ((0)) NOT NULL,
    [Prepare_SP]         BIT            CONSTRAINT [CliSpProto_DF_PrepareSP] DEFAULT ((1)) NOT NULL,
    [Server_Cursor]      BIT            CONSTRAINT [CliSpProto_DF_ServerCur] DEFAULT ((1)) NOT NULL,
    [SP_Desc]            VARCHAR (255)  NULL,
    [SP_Name]            VARCHAR (255)  NOT NULL,
    [Stored_Proc]        BIT            CONSTRAINT [CliSpProto_DF_StoredProc] DEFAULT ((1)) NOT NULL,
    [System]             BIT            CONSTRAINT [CliSpProto_DF_System] DEFAULT ((1)) NOT NULL,
    [Timeout]            TINYINT        CONSTRAINT [CliSpProto_DF_Timeout] DEFAULT ((30)) NOT NULL,
    [TimeoutCount]       TINYINT        CONSTRAINT [CliSpProto_DF_TimeoutCnt] DEFAULT ((0)) NOT NULL,
    [Updated]            BIT            CONSTRAINT [CliSpProto_DF_Updated] DEFAULT ((1)) NOT NULL,
    [VerifyTimeoutCount] TINYINT        NULL,
    [VerifyType_Id]      TINYINT        NULL,
    [Version_Number]     VARCHAR (25)   NULL,
    CONSTRAINT [CliSPPTypes_PK_CliSPId] PRIMARY KEY NONCLUSTERED ([Client_SP_Id] ASC),
    CONSTRAINT [CliSPPTypes_FK_CurTypeId] FOREIGN KEY ([CursorType_Id]) REFERENCES [dbo].[Client_SP_CursorTypes] ([CursorType_Id]),
    CONSTRAINT [CliSPPTypes_FK_LockTypeId] FOREIGN KEY ([LockType_Id]) REFERENCES [dbo].[Client_SP_LockTypes] ([LockType_Id])
);


GO
CREATE UNIQUE CLUSTERED INDEX [CliSPPrototypes_IDX_SPName]
    ON [dbo].[Client_SP_Prototypes]([SP_Name] ASC);

