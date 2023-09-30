CREATE TABLE [dbo].[SDK_Objects] (
    [ObjectId]             INT           IDENTITY (1, 1) NOT NULL,
    [SDKVersion]           VARCHAR (100) NOT NULL,
    [ObjectName]           VARCHAR (100) NULL,
    [ObjectDescription]    VARCHAR (500) NULL,
    [DefaultQueryRowCount] INT           NULL,
    [MainDbTable]          VARCHAR (100) NULL,
    [MessageId]            INT           NULL,
    [NLSPromptId]          INT           NULL,
    [Namespace]            VARCHAR (255) NULL,
    [DllName]              VARCHAR (255) NULL,
    [CanDoWD]              BIT           NULL,
    [WDSPName]             VARCHAR (100) NULL,
    [WDSPSuccessCodes]     VARCHAR (100) NULL,
    [WDSPNoActionCodes]    VARCHAR (100) NULL,
    [WDSPLazyCodes]        VARCHAR (100) NULL,
    [WDSendsMsg]           BIT           NULL,
    [CanDoDEI]             BIT           NULL,
    [DEISPName]            VARCHAR (100) NULL,
    [CanDoESigInfo]        BIT           NULL,
    [ESigInfoSPName]       VARCHAR (100) NULL,
    CONSTRAINT [SDK_Objects_PK_SDKObjectId] PRIMARY KEY CLUSTERED ([ObjectId] ASC)
);

