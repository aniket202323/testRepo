CREATE TABLE [dbo].[Local_E2P_Received_TestMethods] (
    [TestMethodId]      INT           IDENTITY (1, 1) NOT NULL,
    [FPPId]             INT           NOT NULL,
    [Timestamp]         DATETIME      NOT NULL,
    [UniqueId]          VARCHAR (250) NOT NULL,
    [RawMessage]        XML           NOT NULL,
    [TestMethodName]    VARCHAR (50)  NOT NULL,
    [TestMethodVersion] VARCHAR (25)  NOT NULL,
    CONSTRAINT [LocalE2PReceivedTestMethods_PK_TestMethodId] PRIMARY KEY CLUSTERED ([TestMethodId] ASC)
);

