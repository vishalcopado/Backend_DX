@SuppressWarnings('PMD.AvoidGlobalModifier')
global class GetDxNamespace implements copado.ParameterExpressionCallable {
    global String execute(Id contextId) {
        return Settings.NS;
    }
}