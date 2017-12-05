defmodule TS.Mixfile do
	use Mix.Project

	def project do
		[app: :ts,
		 version: "0.1.0",
		 elixir: "~> 1.3",
		 build_embedded: Mix.env==:prod,
		 start_permanent: Mix.env==:prod,
		 deps: deps(),
		 test_coverage: [tool: ExCoveralls],
		 preferred_cli_env: [coveralls: :test],
		 name: "TransportScheduler",
		 source_url: "https://github.com/prasadtalasila/TransportScheduler",
		 docs: [main: "TS",
			extras: ["README.md"]
		       ]
		]
	end

	# Configuration for the OTP application
	#
	# Type "mix help compile.app" for more information
	def application do
		[applications: [:gen_state_machine, :logger, :maru, :edeliver, :httpoison,
			:csvlixir, :exactor, :exprof],
		mod: {TS, []}
		]
	end

	# Dependencies can be Hex packages:
	#
	#   {:mydep, "~> 0.3.0"}
	#
	# Or git/path repositories:
	#
	#   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
	#
	# Type "mix help deps" for more examples and options
	defp deps do
		[{:exactor, "~> 2.1.0"},
		{:gen_state_machine, "~> 1.0"},
		{:maru, "~> 0.11"},
		{:distillery, ">= 0.9.0", warn_missing: false},
		{:edeliver, "~> 1.4.0"},
		{:excoveralls, "~> 0.5", only: :test},
		{:credo, "~> 0.3", only: [:dev, :test]},
		{:exprof, "~> 0.2.0"},
		{:httpoison, "0.11.1"},
		{:csvlixir, "~> 2.0.4"},
		{:ex_doc, "~> 0.14", only: :dev, runtime: false}]
	end
end
