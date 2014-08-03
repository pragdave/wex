# We need these to be compiled into Beam files for the tests

if Mix.env == :test do

  defmodule Wex.Test.Module do
    defmodule WithNoDocs do

      def fn_no_doc(e,f,g), do: [e,f,g]

    end
    
    defmodule WithDocs do
      @moduledoc "docs"

      def fn_no_doc(a,b), do: a+b

      @doc "fn docs"
      def fn_with_doc(c, d\\1), do: c+d

      @doc "arity 0"
      def fn_with_arities, do: nil

      def fn_with_arities(a), do: a

      @doc "arity 2"
      def fn_with_arities(a, b), do: a+b
    end

    defmodule WithNoTypes do
    end

    defmodule WithTypes do
      @type intlist :: [ integer ]
      @type t       :: __MODULE__
    end

    defmodule WithNoSpecs do
    end

    defmodule WithSpecs do
      @type intlist :: [ integer ]
      @type t       :: __MODULE__

      @spec f1(t) :: integer
      def f1(t), do: t

      @spec f2({T,T}) :: T
      def f2({a,b}), do: a+b
    end


  end


end