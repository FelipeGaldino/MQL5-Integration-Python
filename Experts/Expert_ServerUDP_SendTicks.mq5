//+------------------------------------------------------------------+
//|                                                                  |
//|                           ENVIA PARA O CLIENT EM PYTHON TICK ASK |
//|                                                                  |
//+------------------------------------------------------------------+

// SOCKET MSG - VARIAVEIS --------------------------------------------
#include <socketlib.mqh> // CONEXAO SOCKET

// MQL TICK ----------------------------------------------------------
MqlTick last_tick;

// TIME MODEL --------------------------------------------------------
int TimeModel = TIME_DATE | TIME_SECONDS; // TIME - FORMATO

// SOCKET MSG - INPUTS -----------------------------------------------
input string Host = "127.0.0.1"; // HOST
input ushort Port = 8888;        // PORTA

// SOCKET MSG - ARMAZENA A MENSAGEM ----------------------------------
string Msg;
string AskStrMsg;
string AskTickStrTime;

// SOCKET MSG - CLIENTE SOCKET ---------------------------------------
SOCKET64 server = INVALID_SOCKET64;

//+------------------------------------------------------------------+
//|                           ON-TICK                                 |
//+------------------------------------------------------------------+
void OnTick()
{

    // ATRIBUI OS TICKS A VARIAVEL
    SymbolInfoTick(_Symbol, last_tick);

    AskStrMsg = (DoubleToString(last_tick.ask, Digits()));

    // ASK MSG - TIME CONVERTE OS VALORES PARA STRING
    AskTickStrTime = (TimeToString(last_tick.time, TimeModel));

    //------------------------------------------------------ ASK - FORMANDO Msg DE ASK ----------------------------------------------------------------------|

    // ASK - MONTA A BARRA
    Print(" Datetime : " + AskTickStrTime + " Ask Ticks : " + AskStrMsg);

    // ASK MSG - CRIA A MENSAGEM
    Msg = (" Datetime : " + AskTickStrTime + " Ask Ticks : " + AskStrMsg);

    //------------------- CRIA O SERVIDOR SOCKET E ENVIA OS DADOS ARMAZENADOS EM Msg -------------------------------------------------------------------------------------+

    // SOCKET TRADE - RECEBE OS ORDENS DE COMPRA E VENDA DO PYTHON
    if (server != INVALID_SOCKET64)
    {
        char buf[1024] = {0};
        ref_sockaddr ref = {0};
        int len = ArraySize(ref.ref);
        int res = recvfrom(server, buf, 1024, 0, ref.ref, len);
        if (res >= 0)
        {
            // RECEBE DADOS DO PYTHON 
            string receive = CharArrayToString(buf);
            Print(" Python enviou ", receive);
            
            // SOCKET MSG - ENVIA OS DADOS PARA O PYTHON
            string respSend = Msg;
            uchar data[];
            StringToCharArray(respSend, data);

            // SOCKET ERRO - CASO NAO ENVIE OS DADOS PARA O PYTHON
            if (sendto(server, data, ArraySize(data), 0, ref.ref, ArraySize(ref.ref)) == SOCKET_ERROR)
            {
                // SOCKET ERRO - RECEBE O CODIGO DO ERRO E IMPRIME
                int err = WSAGetLastError();
                if (err != WSAEWOULDBLOCK)
                {
                    Print(" Falha no envio : " + WSAErrorDescript(err));
                    CloseClean();
                }
            }
            
            else
            {
                Print("Mensagem Enviada", Msg);
            }
            
        } // SOCKET - FECHA SOCKET

        else
        {
            // SOCKET ERRO - RECEBE O CODIGO DO ERRO E IMPRIME
            int err = WSAGetLastError();
            if (err != WSAEWOULDBLOCK)
            {
                Print("Falha no recebimento: " + WSAErrorDescript(err) + ". Limpar Socket");
                CloseClean();
                return;
            }
        }

    }// SOCKET - FECHA IF CASO DIFERENTE DE INVALIDSOCKET

    else
    {
        // SOCKET CONFIGS - CONFIG UDP WSADATA
        char wsaData[];
        ArrayResize(wsaData, sizeof(WSAData));
        int res = WSAStartup(MAKEWORD(2, 2), wsaData);

        // SOCKET ERRO - VERIFICA SE O PROBLEMA E WSAStartup
        if (res != 0)
        {
            Print(" Falha na inicializacao WSAStartup : " + string(res));
            return;
        }

        // SOCKET CONFIGS - UDP
        server = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

        // SOCKET ERRO - VERIFICA SE O PROBLEMA E INVALID_SOCKET64
        if (server == INVALID_SOCKET64)
        {
            Print("Falha na criacao do Socket : " + WSAErrorDescript(WSAGetLastError()));
            CloseClean();
            return;
        }
        Print("Tentando Conectar..." + Host + ":" + string(Port));

        // SOCKET CONFIGS - PORT HOST
        char ch[];
        StringToCharArray(Host, ch);
        sockaddr_in addrin;
        addrin.sin_family = AF_INET;
        addrin.sin_addr.u.S_addr = inet_addr(ch);
        addrin.sin_port = htons(Port);
        ref_sockaddr ref;
        ref.in = addrin;

        // SOCKET ERRO - VERIFICA SE O PROBLEMA E SOCKET ERROR
        if (bind(server, ref.ref, sizeof(addrin)) == SOCKET_ERROR)
        {
            int err = WSAGetLastError();
            if (err != WSAEISCONN)
            {
                Print("Coneccao com Falha: " + WSAErrorDescript(err) + ". Cleanup socket");
                CloseClean();
                return;
            }
        }

        // SOCKET CONFIGS - DEFINI PARA O MODO SEM BLOQUEIO
        int non_block = 1;
        res = ioctlsocket(server, (int)FIONBIO, non_block);

        // SOCKET ERRO - VERIFICA SE O PROBLEMA E ioctlsocket
        if (res != NO_ERROR)
        {
            Print("Falha erro no ioctlsocket : " + string(res));
            CloseClean();
            return;
        }
        Print("Start Server ok");

    } // FECHA IF DA VERIFICACAO DO SERVER UDP

} // FECHA IF ONTICK

//+------------------------------------------------------------------+
//|                         ON-DEINIT                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    CloseClean();
}

//+------------------------------------------------------------------+
//|                        CLOSE-CLEAN                               |
//+------------------------------------------------------------------+
void CloseClean()
{
    // SOCKET - FECHA SERVIDOR SOCKET
    Print(" Desliga Servidor Socket ");
    if (server != INVALID_SOCKET64)
    {
        closesocket(server);
        server = INVALID_SOCKET64;
    }
    WSACleanup();
}