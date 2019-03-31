%%%-------------------------------------------------------------------
%%% @author hidoshi
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%% 游戏客户端模拟
%%% 模拟过程：平台登录 -> 创角 -> 进入游戏
%%% @end
%%% Created : 17. 十月 2018 10:04
%%%-------------------------------------------------------------------
-module(client).
-author("hidoshi").
-behaviour(gen_server).
-define(IP, "127.0.0.1").
-define(PORT, 5566).
%% API
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2,
  code_change/3]).
-export([start_link/0, login/0, enter_game/0, create_role/0]).
-export([pack/2, write_string/1]).

-record(state, {
  player_name = "",
  player_id = 0
}).

%% 创角
create_role() ->
  gen_server:cast(?MODULE, {create_role}).

%% 平台登录
login() ->
  gen_server:cast(?MODULE, {login}).

%% 进入游戏
enter_game() ->
  gen_server:cast(?MODULE, {enter_game}).

start_link() ->
  {ok, Pid} = gen_server:start(?MODULE, [?IP, ?PORT], []),
  case whereis(?MODULE) of
    undefined ->
      register(?MODULE, Pid);
    _ ->
      skip
  end.

init([Ip, Port]) ->
  case gen_tcp:connect(Ip, Port,
            [binary, {packet, 0}, {active, false}, {reuseaddr, true}, {nodelay, false}, {delay_send, true}]) of
    {error, Reason} ->
      io:format("connect server failed reason ~p~n", [Reason]);
    {ok, Socket} ->
      %% 连接服务器成功
      put(socket, Socket),
      io:format("connect server successed ~n"),
      Pid = spawn(fun() ->client_receive_loop(Socket) end),
      gen_tcp:controlling_process(Socket, Pid),
      Socket
  end,
  {ok, #state{}}.

%% 更新进程state
handle_cast({update_state, Key, Value}, State) ->
  NewState =
    case Key of
      player_id ->
        State#state{player_id = Value};
      player_name ->
        State#state{player_name = Value};
      _ ->
        State
    end,
  {noreply, NewState};

handle_cast({create_role}, State) ->
  %% 随机名字
  BinName = write_string("王" ++ integer_to_list(rand())),
  %% 阵营，职业，性别，名字
  Data = <<1:8, 1:8, 1:8, BinName/binary>>,
  send_msg(pack(10003, Data)),
  {noreply, State#state{player_name = BinName}};

handle_cast({login}, State) ->
  %% 随机平台账号
  Bin1 = write_string("A" ++ integer_to_list(rand())),
  Bin2 = write_string("qodqw4dq65s4d"),
  %% 用户ID，时间戳，平台账号，ticket，服务器验证那里做了屏蔽，这里除了ID随便填
  Id = State#state.player_id,
  Data = <<Id:32, 22222:32, Bin1/binary, Bin2/binary>>,
  send_msg(pack(10000, Data)),
  {noreply, State};

handle_cast({enter_game}, State) ->
  Id = State#state.player_id,
  Data = <<Id:32>>,
  send_msg(pack(10004, Data)),
  {noreply, State};

handle_cast(_Event, _Status) ->
  {noreply, _Status}.

handle_call(_Request, _From, State) ->
  {reply, noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, State) ->
  gen_tcp:close(State),
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%% 循环接收服务器消息
client_receive_loop(Socket) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, BinData} ->
      unpack(BinData),
      client_receive_loop(Socket);
    {error, Reason} ->
      io:format("error happend reason ~p~n", [Reason])
  end.

%% 打包字符串
write_string(S) when is_list(S) ->
  BinString = iolist_to_binary(S),
  Len = byte_size(BinString),
  <<Len:16, BinString/binary>>.

%% 打包数据
pack(Cmd, Data) ->
  Len = byte_size(Data) + 4,
  <<Len:16, Cmd:16, Data/binary>>.

%% 解包服务器返回信息
unpack(Data) ->
  <<_Len:16, Cmd:16, Rest/binary>> = Data,
  case Cmd of
    10000 ->
      <<Result:16>> = Rest,
      io:format("login result ~p~n", [Result]);
    10003 ->
      <<Result:16, PlayerId:32>> = Rest,
      %% 将创角后获得的玩家ID写回进程state
      gen_server:cast(?MODULE, {update_state, player_id, PlayerId}),
      io:format("create role result ~p, Id ~p~n", [Result, PlayerId]);
    10004 ->
      <<Result:16>> = Rest,
      io:format("enter game result ~p~n", [Result]);
    _ ->
      io:format("other cmd ~p~n", [Cmd])
  end.

%% 用于给服务器发送消息
send_msg(Msg) ->
  Socket = get(socket),
  case gen_tcp:send(Socket, Msg) of
    ok ->
      io:format("send msg successed ~n");
    {error, Reason} ->
      io:format("send msg failed reason ~p~n", [Reason])
  end.

%% 生成随机数
rand() ->
  random:seed(erlang:now()),
  trunc(random:uniform() * 10000).