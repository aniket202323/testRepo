CREATE TABLE [comment].[received_messages] (
    [consumer_id]   NVARCHAR (450) NOT NULL,
    [message_id]    NVARCHAR (450) NOT NULL,
    [creation_time] BIGINT         DEFAULT (datediff_big(millisecond,'1970-01-01 00:00:00',getutcdate())) NULL,
    PRIMARY KEY CLUSTERED ([consumer_id] ASC, [message_id] ASC)
);

